// Generated from ../netease/modules/recommend_songs.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 每日推荐歌曲（每日 30 首，需登录）
 *
 * 响应：`{ code, data: { dailySongs: NeteaseSong[], recommendReasons } }`
 */

import { createOption } from "../core/option.js";
                                                      

const recommendSongs                = (query, request) => {
  if (query.cookie && typeof query.cookie === "object") {
    (query.cookie                          ).os = "ios";
  }
  return request("/api/v3/discovery/recommend/songs", {}, createOption(query, "weapi"));
};

export default recommendSongs;
