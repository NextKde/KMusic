// KMusic host adapter. No Electron dependency or global desktop proxy mutation.
export const fetchWithProxy = (input: string | URL, init?: RequestInit): Promise<Response> => fetch(input, init);
export const neteaseLog = { warn: (..._args: unknown[]) => {} };
