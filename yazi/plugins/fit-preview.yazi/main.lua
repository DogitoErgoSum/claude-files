--- @since 26.9.1
-- Makes yazi's preview column exactly as wide as the picture or video it shows (this setup's plugin,
-- see yazi/yazi.toml and yazi/init.lua). A tall photo gets a narrow column and the file list takes
-- the rest; a wide one gets a wide column. Other files use the usual [mgr] ratio.
--
-- How: after a picture is drawn, its previewer reports how many columns it took (M.want). That's
-- remembered per file and terminal height, and Tab:layout gives the preview that many columns.

local MIN_PREVIEW = 8 -- columns
local MIN_LISTS = 30 -- columns always left for the parent + current folder lists

local M = {}

local function key(url, h) return url .. "\0" .. h end

-- How many columns a picture wants, given where it was drawn (rect) inside the area it had
function M.want(rect, area)
	if rect.w >= area.w - 1 and rect.h < area.h - 1 then
		return math.ceil(rect.w * area.h / rect.h) -- cut off by the width: widen until it fills the height
	end
	return rect.w -- fills the height (or is drawn at its own, smaller size): exactly its width
end

function M:setup()
	-- Global, so the previewers of other plugins (video-play) can report sizes too
	FitPreview = { widths = {}, tries = {}, last = nil }

	-- Called from previewers through ya.sync: the hovered file's picture wants `w` columns
	function FitPreview.report(url, h, w)
		local hov = cx.active.current.hovered
		if not hov or tostring(hov.url) ~= url then
			return
		end
		-- What the layout can actually give it (see Tab:layout)
		w = math.max(MIN_PREVIEW - 1, math.min(w, (FitPreview.W or math.huge) - MIN_LISTS - 1))
		local k = key(url, h)
		local old = FitPreview.widths[k]
		local tries = FitPreview.tries[k] or 0
		if (old and math.abs(old - w) <= 1) or tries >= 4 then
			return -- already right (give or take rounding), or not settling: leave it
		end
		FitPreview.widths[k], FitPreview.tries[k] = w, tries + 1
		ya.emit("app:resize", {}) -- lay out again; yazi then previews again in the new area
	end

	local function wanted(tab, h)
		local hov = tab.current.hovered
		return hov and FitPreview.widths[key(tostring(hov.url), h)]
	end

	local layout = Tab.layout
	function Tab:layout()
		local w, W = wanted(self._tab, self._area.h), self._area.w
		FitPreview.last, FitPreview.lastH, FitPreview.W = w, self._area.h, W
		if not w or W < MIN_PREVIEW + MIN_LISTS then
			return layout(self)
		end
		-- +1: Tab:build pads the preview by one column on the right
		local p = math.max(MIN_PREVIEW, math.min(w + 1, W - MIN_LISTS))
		local r = rt.mgr.ratio
		local a = r[1] + r[2] > 0 and math.floor((W - p) * r[1] / (r[1] + r[2])) or 0
		self._chunks = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints({
				ui.Constraint.Length(a),
				ui.Constraint.Length(W - p - a),
				ui.Constraint.Length(p),
			})
			:split(self._area)
	end

	-- Moving to a file whose width is already known (or to a non-picture) re-lays out right away
	ps.sub("hover", function()
		if FitPreview.lastH and wanted(cx.active, FitPreview.lastH) ~= FitPreview.last then
			ya.emit("app:resize", {})
		end
	end)
end

-- The previewer for pictures: the same as yazi's own (image, svg, magick), then it reports the size
local report = ya.sync(function(_, url, h, w)
	if FitPreview then
		FitPreview.report(url, h, w)
	end
end)

local function base(mime)
	mime = mime or ""
	if mime == "image/svg+xml" then
		return "svg"
	elseif mime == "image/avif" or mime == "image/jxl" or mime:match("^image/hei.$") then
		return "magick"
	end
	return "image"
end

function M:peek(job)
	local name, start, cache = base(job.mime), ya.time(), ya.file_cache(job)
	local url = cache
	if name == "image" then
		if not cache or not fs.cha(cache) then
			url = Url(job.file.path)
		end
	else
		if not cache then
			return
		end
		local ok, err = require(name):preload(job)
		if not ok or err then
			return ya.preview_widget(job, err)
		end
	end
	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - ya.time()))
	local rect, err = ya.image_show(url, job.area)
	ya.preview_widget(job, err)
	if rect then
		report(tostring(job.file.url), job.area.h, M.want(rect, job.area))
	end
end

function M:seek() end

function M:preload(job) return require(base(job.mime)):preload(job) end

function M:spot(job) return require("image"):spot(job) end

return M
