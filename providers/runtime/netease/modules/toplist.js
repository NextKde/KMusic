// Generated from ../netease/modules/toplist.ts by tools/build-provider-runtime.mjs; edit the TS source.
// KMusic endpoint adapter, not a module copied from pinned SPlayer Next.
// Uses the attributed SPlayer request stack; endpoint cross-checked against
// NeteaseCloudMusicApiEnhanced/api-enhanced module/toplist.js.
import { createOption } from "../core/option.js";
                                                      
const toplist                = (query, request) => request("/api/toplist", {}, createOption(query, "weapi"));
export default toplist;
