local status, pretty_fold = pcall(require, "pretty-fold")
if not status then
	return
end
local status2, fold_preview = pcall(require, "fold-preview")
if not status2 then
	return
end

pretty_fold.setup()
fold_preview.setup()
