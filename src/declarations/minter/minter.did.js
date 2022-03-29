export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Graduate = IDL.Record({
    'status' : IDL.Text,
    'track' : IDL.Text,
    'username' : IDL.Text,
    'date' : IDL.Text,
    'name' : IDL.Text,
    'preference' : IDL.Nat,
    'desc1' : IDL.Text,
    'desc2' : IDL.Text,
  });
  const TokenId = IDL.Nat;
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const Request = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const StreamingCallbackToken = IDL.Record({
    'key' : IDL.Text,
    'index' : IDL.Nat,
    'content_encoding' : IDL.Text,
  });
  const StreamingCallbackResponse = IDL.Record({
    'token' : IDL.Opt(StreamingCallbackToken),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const StreamingCallback = IDL.Func(
      [StreamingCallbackToken],
      [StreamingCallbackResponse],
      ['query'],
    );
  const StreamingStrategy = IDL.Variant({
    'Callback' : IDL.Record({
      'token' : StreamingCallbackToken,
      'callback' : StreamingCallback,
    }),
  });
  const Response = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
  const DRC721 = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Principal], [Result], []),
    'admin_update_graduate' : IDL.Func([IDL.Nat, Graduate], [IDL.Text], []),
    'approve' : IDL.Func([IDL.Principal, TokenId], [], []),
    'balanceOf' : IDL.Func([IDL.Principal], [IDL.Opt(IDL.Nat)], []),
    'getApproved' : IDL.Func([IDL.Nat], [IDL.Principal], []),
    'getRegistry' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(TokenId, IDL.Principal))],
        ['query'],
      ),
    'get_diploma' : IDL.Func([IDL.Principal], [IDL.Opt(Graduate)], []),
    'get_token_by_principal' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(IDL.Nat)],
        [],
      ),
    'http_request' : IDL.Func([Request], [Response], ['query']),
    'isApprovedForAll' : IDL.Func(
        [IDL.Principal, IDL.Principal],
        [IDL.Bool],
        [],
      ),
    'mint' : IDL.Func([IDL.Principal, Graduate], [IDL.Nat], []),
    'name' : IDL.Func([], [IDL.Text], ['query']),
    'ownerOf' : IDL.Func([TokenId], [IDL.Opt(IDL.Principal)], []),
    'setApprovalForAll' : IDL.Func([IDL.Principal, IDL.Bool], [], ['oneway']),
    'set_svg_template' : IDL.Func([IDL.Text], [], ['oneway']),
    'symbol' : IDL.Func([], [IDL.Text], ['query']),
    'tokenURI' : IDL.Func([TokenId], [IDL.Opt(IDL.Text)], ['query']),
    'transferFrom' : IDL.Func([IDL.Text, IDL.Text, IDL.Nat], [], ['oneway']),
    'update_uri' : IDL.Func([IDL.Nat, IDL.Text, IDL.Nat], [IDL.Text], []),
  });
  return DRC721;
};
export const init = ({ IDL }) => { return [IDL.Text, IDL.Text]; };
