import Error "mo:base/Error";
import Http "types/http";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Pattern "mo:base/Text";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import T "dip721_types";

actor class DRC721(_name : Text, _symbol : Text) {

    //Using DIP721 standard, adapted from https://github.com/SuddenlyHazel/DIP721/blob/main/src/DIP721/DIP721.mo
    private stable var tokenPk : Nat = 0;

    private stable var tokenURIEntries : [(T.TokenId, Text)] = [];
    private stable var ownersEntries : [(T.TokenId, Principal)] = [];
    private stable var balancesEntries : [(Principal, Nat)] = [];
    private stable var tokenApprovalsEntries : [(T.TokenId, Principal)] = [];
    private stable var operatorApprovalsEntries : [(Principal, [Principal])] = [];  

    private let tokenURIs : HashMap.HashMap<T.TokenId, Text> = HashMap.fromIter<T.TokenId, Text>(tokenURIEntries.vals(), 10, Nat.equal, Hash.hash);
    private let owners : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(ownersEntries.vals(), 10, Nat.equal, Hash.hash);
    private let balances : HashMap.HashMap<Principal, Nat> = HashMap.fromIter<Principal, Nat>(balancesEntries.vals(), 10, Principal.equal, Principal.hash);
    private let tokenApprovals : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(tokenApprovalsEntries.vals(), 10, Nat.equal, Hash.hash);
    private let operatorApprovals : HashMap.HashMap<Principal, [Principal]> = HashMap.fromIter<Principal, [Principal]>(operatorApprovalsEntries.vals(), 10, Principal.equal, Principal.hash);

    private type Pattern = Pattern.Pattern;
    private type Iter<T> = Iter.Iter<T>;

    public shared func balanceOf(p : Principal) : async ?Nat {
        return balances.get(p);
    };

    public shared func ownerOf(tokenId : T.TokenId) : async ?Principal {
        return _ownerOf(tokenId);
    };

    public shared query func tokenURI(tokenId : T.TokenId) : async ?Text {
        return _tokenURI(tokenId);
    };

    public shared query func name() : async Text {
        return _name;
    };

    public shared query func symbol() : async Text {
        return _symbol;
    };

    public shared func isApprovedForAll(owner : Principal, opperator : Principal) : async Bool {
        return _isApprovedForAll(owner, opperator);
    };

    public shared(msg) func approve(to : Principal, tokenId : T.TokenId) : async () {
        switch(_ownerOf(tokenId)) {
            case (?owner) {
                 assert to != owner;
                 assert msg.caller == owner or _isApprovedForAll(owner, msg.caller);
                 _approve(to, tokenId);
            };
            case (null) {
                throw Error.reject("No owner for token")
            };
        }
    };

    public shared func getApproved(tokenId : Nat) : async Principal {
        switch(_getApproved(tokenId)) {
            case (?v) { return v };
            case null { throw Error.reject("None approved")}
        }
    };

    public shared(msg) func setApprovalForAll(op : Principal, isApproved : Bool) : () {
        assert msg.caller != op;

        switch (isApproved) {
            case true {
                switch (operatorApprovals.get(msg.caller)) {
                    case (?opList) {
                        var array = Array.filter<Principal>(opList,func (p) { p != op });
                        array := Array.append<Principal>(array, [op]);
                        operatorApprovals.put(msg.caller, array);
                    };
                    case null {
                        operatorApprovals.put(msg.caller, [op]);
                    };
                };
            };
            case false {
                switch (operatorApprovals.get(msg.caller)) {
                    case (?opList) {
                        let array = Array.filter<Principal>(opList, func(p) { p != op });
                        operatorApprovals.put(msg.caller, array);
                    };
                    case null {
                        operatorApprovals.put(msg.caller, []);
                    };
                };
            };
        };
        
    };

    public shared(msg) func transferFrom(from : Principal, to : Principal, tokenId : Nat) : () {
        assert _isAdmin(msg.caller);

        _transfer(from, to, tokenId);
    };

    // Mint without authentication
/*
    public func mint_principal(uri : Text, principal : Principal) : async Nat {
        tokenPk += 1;
        _mint(principal, tokenPk, uri);
        return tokenPk;
    };
*/

    // Mint requires authentication in the frontend as we are using caller.
     public shared(msg) func mint(uri : Text) : async Nat {
      //  assert _isAdmin(msg.caller);

        tokenPk += 1;
        _mint(msg.caller, tokenPk, uri);
        return tokenPk;
    };

        // change uri.
    //  public shared (msg) func update(uri : Text, tokenId : Nat) {
    //     assert _isAdmin(msg.caller);

    //     tokenPk += 1;
    //     _mint(msg.caller, tokenPk, uri);
    //     return tokenPk;
    // };

///////////////////////////////////////////////////////////////

    //////////
    // HTTP //
    //////////



    public query func http_request(request : Http.Request) : async Http.Response {
        let iterator = Text.split(request.url, #text("tokenid="));
        let array = Iter.toArray(iterator);
        let tokenId = _text_to_Nat(array[array.size() - 1]);
        switch(_tokenURI(tokenId)) {
            case(null) {{body = Blob.fromArray([0]); headers = [("Content-Type", "text/html; charset=UTF-8")];  streaming_strategy = null; status_code = 404;}};
            case(?text) {{body = (Text.encodeUtf8(text)); headers = [("Content-Type", "text/html; charset=UTF-8")]; streaming_strategy = null; status_code = 200;}};
        };
//        if (tokenURIs.get(token_identifier) == null) {
//            {body = Blob.fromArray([0]); headers = [("Content-Type", "text/html; charset=UTF-8")];  streaming_strategy = null; status_code = 404;}
//        } else {
           //   {body = (Text.encodeUtf8(_tokenURI(tokenId))); headers = [("Content-Type", "text/html; charset=UTF-8")]; streaming_strategy = null; status_code = 200;}
//        };
        //switch(tokenURIs.get(tokenId)){
        //    case(null) {{body = Blob.fromArray([0]); headers = [("Content-Type", "text/html; charset=UTF-8")];  streaming_strategy = null; status_code = 404;}};
        //    case(?#Material(name)) {_streamStaticAsset(name)};
        //    case(?#LegendaryAccessory(legendary)) {_streamStaticAsset(legendary.name)};
        //    case(?#Accessory(accessory)) {_streamAccessory(token_index)};
        //};
    };
/*
    private func _streamStaticAsset(name : Text) : Http.Response {
        switch(_templates.get(name)){
            case(null) {{body = (Text.encodeUtf8("Template not found. (critical error)")); headers = [("Content-Type", "text/html; charset=UTF-8")]; streaming_strategy = null; status_code = 200;}};
            case(?#Material(blob)){{body = blob; headers = [("Content-Type", "image/svg+xml")]; streaming_strategy = null; status_code = 200;}}; //TODO check content type
            case(?#LegendaryAccessory(blob)){{body = blob; headers = [("Content-Type", "image/svg+xml")]; streaming_strategy = null; status_code = 200;}};
            case(_) {{body = (Text.encodeUtf8("Error unreacheable")); headers = [("Content-Type", "image/svg+xml")]; streaming_strategy = null; status_code = 200;}};
        }
    };  

    private func _streamAccessory(token_index : TokenIndex) : Http.Response {
        switch(_blobs.get(token_index)){
            case(null) {{body = (Text.encodeUtf8("Accessory not found. (critical error)")); headers = [("Content-Type", "text/html; charset=UTF-8")]; streaming_strategy = null; status_code = 200;}};
            case(?blob) {{body = blob; headers = [("Content-Type", "image/svg+xml")]; streaming_strategy = null; status_code = 200; }}
        }
    };

*/

//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////

    ///////////
    // ADMIN //
    ///////////

    let dfx_identity_principal_isaac : Principal = Principal.fromText("ijeuu-g4z7n-jndij-hzfqh-fe2kw-7oan5-pcmgj-gh3zn-onsas-dqm7c-nqe");
    let plug_principle_isaac : Principal = Principal.fromText("gj3h2-k3kw2-ciszt-6zylp-azl7o-mvg5j-eudtf-fpejf-mx2rd-ifsul-dqe");

    var admins : [Principal] = [dfx_identity_principal_isaac, plug_principle_isaac]; 

    private func _isAdmin (p: Principal) : Bool {
        return(_contains<Principal>(admins, p, Principal.equal))
    };

    // Any admin can add others as admin
    public shared(msg) func addAdmin (p : Principal) : async Result.Result<(), Text> {
        if (_isAdmin(msg.caller)) {
            admins := Array.append<Principal>(admins, [p]);
            return #ok ();
        } else {
            return #err ("You are not authorized!");
        }

    };

    // building SVG
    private func _build_svg(temp_uri : Text) : Text {
        let pattern : Pattern = #text("<>");
        let split_text : Iter<Text> = Text.split(temp_uri, pattern);
        let template : [Text] = ["||","||","||","</svg>"];
        var count : Nat = 0;
        var content : Text = "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg' class=''>";

        for (field in split_text) {
            content #= field # template[count];
            count += 1;
        };

        return content;
    };

    // Internal
    private func _text_to_Nat( t : Text) : Nat {
        var count : Nat = 0;
        var n : Nat = 0;
        var text_dig : Text = "";

        // remove all non-numeric characters
        for (char in Text.toIter(t)) {
            if (Char.isDigit(char)) {
                text_dig := Char.toText(char) # text_dig;
            };
        };

        // interate through, adding up the number
        for (char in Text.toIter(text_dig)) {
            n += Nat32.toNat(Char.toNat32(char) - 48) * (10 ** count);
            count += 1;
        };

        return n;    
    };

    private func _ownerOf(tokenId : T.TokenId) : ?Principal {
        return owners.get(tokenId);
    };

    private func _tokenURI(tokenId : T.TokenId) : ?Text {
        return tokenURIs.get(tokenId);
    };

    private func _isApprovedForAll(owner : Principal, opperator : Principal) : Bool {
        switch (operatorApprovals.get(owner)) {
            case(?whiteList) {
                for (allow in whiteList.vals()) {
                    if (allow == opperator) {
                        return true;
                    };
                };
            };
            case null {return false;};
        };
        return false;
    };

    private func _approve(to : Principal, tokenId : Nat) : () {
        tokenApprovals.put(tokenId, to);
    };

    private func _removeApprove(tokenId : Nat) : () {
        let _ = tokenApprovals.remove(tokenId);
    };

    private func _exists(tokenId : Nat) : Bool {
        return Option.isSome(owners.get(tokenId));
    };

    private func _getApproved(tokenId : Nat) : ?Principal {
        assert _exists(tokenId) == true;
        switch(tokenApprovals.get(tokenId)) {
            case (?v) { return ?v };
            case null {
                return null;
            };
        }
    };

    private func _hasApprovedAndSame(tokenId : Nat, spender : Principal) : Bool {
        switch(_getApproved(tokenId)) {
            case (?v) {
                return v == spender;
            };
            case null { return false}
        }
    };

    private func _isApprovedOrOwner(spender : Principal, tokenId : Nat) : Bool {
        assert _exists(tokenId);
        let owner = Option.unwrap(_ownerOf(tokenId));
        return spender == owner or _hasApprovedAndSame(tokenId, spender) or _isApprovedForAll(owner, spender);
    };

    private func _transfer(from : Principal, to : Principal, tokenId : Nat) : () {
        assert _exists(tokenId);
        assert Option.unwrap(_ownerOf(tokenId)) == from;

        // Bug in HashMap https://github.com/dfinity/motoko-base/pull/253/files
        // this will throw unless you patch your file
        _removeApprove(tokenId);

        _decrementBalance(from);
        _incrementBalance(to);
        owners.put(tokenId, to);
    };

    private func _incrementBalance(address : Principal) {
        switch (balances.get(address)) {
            case (?v) {
                balances.put(address, v + 1);
            };
            case null {
                balances.put(address, 1);
            }
        }
    };

    private func _decrementBalance(address : Principal) {
        switch (balances.get(address)) {
            case (?v) {
                balances.put(address, v - 1);
            };
            case null {
                balances.put(address, 0);
            }
        }
    };

    private func _mint(to : Principal, tokenId : Nat, uri : Text) : () {
        assert not _exists(tokenId);

        //let full_uri : Text = _build_svg(uri);
        _incrementBalance(to);
        owners.put(tokenId, to);
        tokenURIs.put(tokenId,uri)
    };

    private func _burn(tokenId : Nat) {
        let owner = Option.unwrap(_ownerOf(tokenId));

        _removeApprove(tokenId);
        _decrementBalance(owner);

        ignore owners.remove(tokenId);
    };

    private func _contains<T>(xs : [T], y : T, equal : (T, T) -> Bool) : Bool {
        for (x in xs.vals()) {
            if (equal(x, y)) return true;
        }; false;
    };

    system func preupgrade() {
        tokenURIEntries := Iter.toArray(tokenURIs.entries());
        ownersEntries := Iter.toArray(owners.entries());
        balancesEntries := Iter.toArray(balances.entries());
        tokenApprovalsEntries := Iter.toArray(tokenApprovals.entries());
        operatorApprovalsEntries := Iter.toArray(operatorApprovals.entries());
        
    };

    system func postupgrade() {
        tokenURIEntries := [];
        ownersEntries := [];
        balancesEntries := [];
        tokenApprovalsEntries := [];
        operatorApprovalsEntries := [];
    };
};