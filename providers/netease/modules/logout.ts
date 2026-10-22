/**
 * 退出登录
 */

import { createOption } from "../core/option.ts";
import type { NeteaseModule } from "../core/types.ts";

const logout: NeteaseModule = (query, request) => request("/api/logout", {}, createOption(query));

export default logout;
