// Generated from ../netease/modules/album_sublist.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 用户收藏的专辑列表
 *
 * params:
 * - limit / offset 分页
 *
 * 响应：`{ code, count, hasMore, data: [{ id, name, picUrl, artists, ... }] }`
 */

import { createOption } from "../core/option.js";
                                                      

const albumSublist                = (query, request) => {
  const data = {
    limit: query.limit ?? 50,
    offset: query.offset ?? 0,
    total: true,
  };
  return request("/api/album/sublist", data, createOption(query, "weapi"));
};

export default albumSublist;
