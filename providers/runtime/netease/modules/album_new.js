// Generated from ../netease/modules/album_new.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 新碟上架（无需登录）
 *
 * 响应：`{ code, albums: NeteaseAlbum[] }`
 */

import { createOption } from "../core/option.js";
                                                      

const albumNew                = (query, request) => {
  const data = { area: "ALL", offset: 0, total: true, limit: query.limit ?? 30 };
  return request("/api/album/new", data, createOption(query, "weapi"));
};

export default albumNew;
