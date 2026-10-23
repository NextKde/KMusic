// Generated from ../netease/modules/recommend_resource.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 每日推荐歌单 / 专属歌单（需登录）
 *
 * 响应：`{ code, recommend: NeteasePlaylist[] }`
 */

import { createOption } from "../core/option.js";
                                                      

const recommendResource                = (query, request) => {
  return request("/api/v1/discovery/recommend/resource", {}, createOption(query, "weapi"));
};

export default recommendResource;
