// KMusic endpoint adapter, not a module copied from pinned SPlayer Next.
// Uses the attributed SPlayer request stack; endpoint cross-checked against
// NeteaseCloudMusicApiEnhanced/api-enhanced module/toplist.js.
import { createOption } from "../core/option.ts";
import type { NeteaseModule } from "../core/types.ts";
const toplist: NeteaseModule = (query, request) => request("/api/toplist", {}, createOption(query, "weapi"));
export default toplist;
