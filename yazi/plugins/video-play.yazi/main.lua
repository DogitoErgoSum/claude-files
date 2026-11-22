--- @since 26.9.1
-- Video previews with a play button (this setup's plugin, see yazi/yazi.toml and yazi/init.lua).
-- Hovering a video shows its thumbnail in yazi's preview with "▶ Play" under it.
-- Click the preview to play the video right there; click again to pause. Moving to another file stops it.
-- ffmpeg writes the frames that yazi draws, and plays the sound through the Mac's speakers.

local FPS = 12 -- frames per second while playing: more is smoother but costs more CPU
local CONTROLS = 2 -- rows kept under the picture for the button and the time
local CONTROLS_W = 22 -- columns the button and the time need, so a narrow video still gets that much room

local M = {}

-- State shared by the previewer and the click handler (both run this file, in different contexts)
local load = ya.sync(function(st, url)
	st.token = st.token or string.format("yazi-video-play-%d-%d", os.time(), math.random(1e9))
	st.shown = url
	st.pos, st.frame = st.pos or {}, st.frame or {}
	st.gen = (st.gen or 0) + 1 -- each preview run gets a number, so an older play loop knows to stop
	return { token = st.token, gen = st.gen, playing = st.playing == url, pos = st.pos[url] or 0, frame = st.frame[url] }
end)

-- Should this play loop keep going? Returns "play", "pause" (clicked: keep the frame and show ▶ Play),
-- "away" (another file is hovered: stop, and don't start again on return) or "rerun" (a newer preview took over).
local check = ya.sync(function(st, url, gen)
	local h = cx.active.current.hovered
	if not h or tostring(h.url) ~= url then
		if st.playing == url then
			st.playing = nil
		end
		return "away"
	elseif st.gen ~= gen then
		return "rerun"
	end
	return st.playing == url and "play" or "pause"
end)

local save = ya.sync(function(st, url, pos, frame) st.pos[url], st.frame[url] = pos, frame end)

-- Tell fit-preview.yazi how wide the picture is, so the preview column matches it
local report = ya.sync(function(_, url, h, w)
	if FitPreview then
		FitPreview.report(url, h, w)
	end
end)

local finished = ya.sync(function(st, url)
	st.playing, st.pos[url], st.frame[url] = nil, nil, nil
end)

-- The click handler: play or pause the video shown in the preview
local toggle = ya.sync(function(st)
	local h = cx.active.current.hovered
	if not h or tostring(h.url) ~= st.shown then
		return false
	end
	st.playing = st.playing ~= st.shown and st.shown or nil
	return st.playing ~= nil
end)

local function clock(s)
	s = math.floor(s or 0)
	return string.format("%d:%02d", s // 60, s % 60)
end

local function picture_area(area)
	return ui.Rect { x = area.x, y = area.y, w = area.w, h = math.max(1, area.h - CONTROLS) }
end

-- "▶ Play  0:12 / 1:30", centred under the picture
local function controls(job, rect, label, pos, dur)
	rect = rect or picture_area(job.area)
	local line = ui.Line {
		ui.Span(" " .. label .. " "):reverse():bold(),
		ui.Span(dur and string.format("  %s / %s", clock(pos), clock(dur)) or ""):fg("gray"),
	}
	local y = math.min(rect.y + rect.h + 1, job.area.y + job.area.h - 1)
	return { line:area(ui.Rect { x = rect.x, y = y, w = rect.w, h = 1 }):align(ui.Align.CENTER) }
end

-- Length in seconds, and whether there's a sound track
local function probe(path)
	local out = Command("ffprobe")
		:arg({ "-v", "quiet", "-show_entries", "format=duration:stream=codec_type", "-of", "json", tostring(path) })
		:stdout(Command.PIPED)
		:output()
	local t = out and ya.json_decode(out.stdout) or {}
	local audio = false
	for _, s in ipairs(t.streams or {}) do
		audio = audio or s.codec_type == "audio"
	end
	return tonumber((t.format or {}).duration), audio
end

local function sh(script, ...) Command("/bin/sh"):arg({ "-c", script, "sh", ... }):status() end

function M:setup()
	-- Moving to another file stops the video (yazi cancels its preview); coming back shows ▶ Play
	-- with the spot it got to, instead of playing again by itself.
	ps.sub("hover", function()
		local h = cx.active.current.hovered
		if self.playing and (not h or tostring(h.url) ~= self.playing) then
			self.playing = nil
		end
	end)

	-- Clicking the preview of a video plays / pauses it; clicks elsewhere work as before
	local click = Preview.click
	function Preview:click(event, up)
		local h = cx.active.current.hovered
		if not up and event.is_left and h and not h.cha.is_dir then
			return ya.emit("plugin", { "video-play" })
		end
		return click(self, event, up)
	end
end

function M:entry()
	if toggle() then
		ya.emit("peek", { force = true })
	end
end

function M:peek(job)
	local url = tostring(job.file.url)
	local st = load(url)
	Command("pkill"):arg({ "-f", st.token }):status() -- stop an earlier run's ffmpeg, if any
	local dur, audio = probe(job.file.path)
	if st.playing then
		return self:play(job, st, dur, audio)
	end

	-- Paused part-way: show that frame. Otherwise yazi's usual thumbnail.
	local img = st.frame and Url(st.frame)
	if not (img and fs.cha(img)) then
		local start, cache = ya.time(), ya.file_cache(job)
		if not cache then
			return
		end
		local ok, err = require("video"):preload(job)
		if not ok or err then
			return ya.preview_widget(job, err)
		end
		ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - ya.time()))
		img = cache
	end
	local area = picture_area(job.area)
	local rect, err = ya.image_show(img, area)
	if err then
		return ya.preview_widget(job, err)
	end
	ya.preview_widget(job, controls(job, rect, "▶ Play", st.pos, dur))
	if rect then
		report(url, job.area.h, math.max(CONTROLS_W, require("fit-preview").want(rect, area)))
	end
end

function M:seek(job) require("video"):seek(job) end

function M:play(job, st, dur, audio)
	local url = tostring(job.file.url)
	local dir = string.format("%s/%s", (os.getenv("TMPDIR") or "/tmp/"):gsub("/$", ""), st.token)
	sh('rm -rf "$1" && mkdir -p "$1"', dir)

	local w, h = rt.preview.max_width, rt.preview.max_height
	local args = {
		"-v", "error", "-nostdin", "-re", "-ss", string.format("%.2f", st.pos), "-i", tostring(job.file.path),
		"-map", "0:v:0", "-vf", string.format("fps=%d,scale='min(%d,iw)':'min(%d,ih)':force_original_aspect_ratio=decrease", FPS, w, h),
		"-q:v", "5", "-atomic_writing", "1", dir .. "/%06d.jpg",
	}
	if audio then
		for _, a in ipairs { "-map", "0:a:0", "-f", "audiotoolbox", "-" } do args[#args + 1] = a end
	end
	local child, err = Command("ffmpeg"):arg(args):stdout(Command.NULL):stderr(Command.NULL):spawn()
	if not child then
		return ya.preview_widget(job, Err("Failed to start `ffmpeg`: %s", err))
	end

	local area, n, label_at, rect = picture_area(job.area), 0, -1, nil
	local frame = function(i) return string.format("%s/%06d.jpg", dir, i) end
	while true do
		local next = check(url, st.gen)
		if next ~= "play" then
			child:start_kill()
			if next == "pause" then -- keep the frame on screen and show the Play button
				ya.preview_widget(job, controls(job, rect, "▶ Play", st.pos + n / FPS, dur))
			end
			return
		end

		local last = n -- skip ahead to the newest finished frame if we're behind
		while fs.cha(Url(frame(last + 1))) do
			last = last + 1
		end
		if last > n then
			rect = ya.image_show(Url(frame(last)), area) or rect
			for i = math.max(1, n), last - 1 do
				fs.remove("file", Url(frame(i)))
			end
			n = last
			local pos = st.pos + n / FPS
			save(url, pos, frame(n))
			if math.floor(pos) ~= label_at then
				label_at = math.floor(pos)
				ya.preview_widget(job, controls(job, rect, "⏸ Pause", pos, dur))
			end
		elseif child:try_wait() then -- the end: back to the thumbnail
			finished(url)
			sh('rm -rf "$1"', dir)
			return ya.emit("peek", { force = true, only_if = job.file.url })
		end
		ya.sleep(0.5 / FPS)
	end
end

return M
