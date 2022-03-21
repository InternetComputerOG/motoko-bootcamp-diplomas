import type { Principal } from '@dfinity/principal';
export interface DRC721 {
  'addAdmin' : (arg_0: Principal) => Promise<Result>,
  'admin_update_uri' : (arg_0: bigint, arg_1: Graduate) => Promise<string>,
  'approve' : (arg_0: Principal, arg_1: TokenId) => Promise<undefined>,
  'balanceOf' : (arg_0: Principal) => Promise<[] | [bigint]>,
  'getApproved' : (arg_0: bigint) => Promise<Principal>,
  'getRegistry' : () => Promise<Array<[TokenId, Principal]>>,
  'get_diploma' : (arg_0: Principal) => Promise<[] | [Graduate]>,
  'http_request' : (arg_0: Request) => Promise<Response>,
  'isApprovedForAll' : (arg_0: Principal, arg_1: Principal) => Promise<boolean>,
  'mint' : (arg_0: Principal, arg_1: Graduate) => Promise<bigint>,
  'name' : () => Promise<string>,
  'ownerOf' : (arg_0: TokenId) => Promise<[] | [Principal]>,
  'setApprovalForAll' : (arg_0: Principal, arg_1: boolean) => Promise<
      undefined
    >,
  'set_svg_template' : (arg_0: string) => Promise<undefined>,
  'symbol' : () => Promise<string>,
  'tokenURI' : (arg_0: TokenId) => Promise<[] | [string]>,
  'transferFrom' : (
      arg_0: Principal,
      arg_1: Principal,
      arg_2: bigint,
    ) => Promise<undefined>,
  'update_uri' : (arg_0: bigint, arg_1: string, arg_2: bigint) => Promise<
      string
    >,
}
export interface Graduate {
  'status' : string,
  'track' : string,
  'username' : string,
  'date' : string,
  'name' : string,
  'preference' : bigint,
  'desc1' : string,
  'desc2' : string,
}
export type HeaderField = [string, string];
export interface Request {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface Response {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export type Result = { 'ok' : null } |
  { 'err' : string };
export type StreamingCallback = (arg_0: StreamingCallbackToken) => Promise<
    StreamingCallbackResponse
  >;
export interface StreamingCallbackResponse {
  'token' : [] | [StreamingCallbackToken],
  'body' : Array<number>,
}
export interface StreamingCallbackToken {
  'key' : string,
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken,
      'callback' : StreamingCallback,
    }
  };
export type TokenId = bigint;
export interface _SERVICE extends DRC721 {}
