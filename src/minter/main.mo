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
    private stable var svg_art : [var Text] = Array.thaw(["0","1","2","3","4","5","6"]);
    private stable var graduateEntries : [(T.TokenId, Graduate)] = [];    

    private let tokenURIs : HashMap.HashMap<T.TokenId, Text> = HashMap.fromIter<T.TokenId, Text>(tokenURIEntries.vals(), 10, Nat.equal, Hash.hash);
    private let owners : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(ownersEntries.vals(), 10, Nat.equal, Hash.hash);
    private let balances : HashMap.HashMap<Principal, Nat> = HashMap.fromIter<Principal, Nat>(balancesEntries.vals(), 10, Principal.equal, Principal.hash);
    private let tokenApprovals : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(tokenApprovalsEntries.vals(), 10, Nat.equal, Hash.hash);
    private let operatorApprovals : HashMap.HashMap<Principal, [Principal]> = HashMap.fromIter<Principal, [Principal]>(operatorApprovalsEntries.vals(), 10, Principal.equal, Principal.hash);
    private let graduates : HashMap.HashMap<T.TokenId, Graduate> = HashMap.fromIter<T.TokenId, Graduate>(graduateEntries.vals(), 10, Nat.equal, Hash.hash);

    private type Pattern = Pattern.Pattern;
    private type Iter<T> = Iter.Iter<T>;
    public type Graduate = {
        name : Text;
        username : Text;
        preference : Nat;
        desc1 : Text;
        desc2 : Text;
        track : Text;
        date : Text;
        status : Text;
    };

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

    public shared(msg) func transferFrom(from : Text, to : Text, tokenId : Nat) : () {
        assert _isAdmin(msg.caller);

        _transfer(Principal.fromText(from), Principal.fromText(to), tokenId);
    };

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

// Start of construction area

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
    

    public shared(msg) func mint(to : Text, graduate : Graduate) : async Nat {
        assert(_isAdmin(msg.caller));
        assert(balances.get(Principal.fromText(to)) != ?1);

        tokenPk += 1;
        _mint(Principal.fromText(to), tokenPk, graduate);
        return tokenPk;
    };

    public shared(msg) func update_uri(tokenId : Nat, status : Text, preference : Nat) : async Text {
        assert(_isOwner(msg.caller, tokenId));

        switch(graduates.get(tokenId)) {
            case(null) return "Diploma with ID " # Nat.toText(tokenId) # " not found...";
            case(?value) {
                let graduate : Graduate = {
                    name = value.name;
                    username = value.username;
                    preference = preference;
                    desc1 = value.desc1;
                    desc2 = value.desc2;
                    track = value.track;
                    date = value.date;
                    status = status; 
                };

                _replace_uri(graduate, tokenId);

                return "Diploma Updated";
            };
        };
    };


    public shared(msg) func admin_update_graduate(tokenId : Nat, graduate : Graduate) : async Text {    
        assert(_isAdmin(msg.caller));

        switch(graduates.get(tokenId)) {
            case(null) {
                _replace_uri(graduate, tokenId);

                return "Diploma Created & Updated";
            };
            case(?value) {
                _replace_uri(graduate, tokenId);

                return "Diploma Updated";
            };
        };
    };

    public shared(msg) func get_diploma(principal : Principal) : async ?Graduate {
        assert(msg.caller == principal or _isAdmin(msg.caller));
        let tokenId : ?Nat = _getTokenByPrincipal(principal);
        
        switch (tokenId) {
            case(null) return null;
            case(?value) return graduates.get(value);
        };
    };

    public query func getRegistry() : async [(T.TokenId, Principal)] {
        return _getEntries();
    };

    public shared(msg) func set_svg_template(text : Text) {
        assert _isAdmin(msg.caller);
        var i = 0;

        for (string in Text.split(text, #text "||SPLIT||")) {
            svg_art[i] := string;
            i += 1;
        };
    };

    public shared(msg) func get_token_by_principal(principal : Principal) : async ?Nat {
        assert(msg.caller == principal or _isAdmin(msg.caller));
        return _getTokenByPrincipal(principal);
    };

///////////////////////////////////////////////////////////////

    //////////
    // HTTP //
    //////////

///////////////////////////////////////////////////////////////


    public query func http_request(request : Http.Request) : async Http.Response {
        let iterator = Text.split(request.url, #text("tokenid="));
        let array = Iter.toArray(iterator);
        let tokenId = _text_to_Nat(array[array.size() - 1]);
        switch(_tokenURI(tokenId)) {
            case(null) {{body = Blob.fromArray([0]); headers = [("Content-Type", "text/html; charset=UTF-8")];  streaming_strategy = null; status_code = 404;}};
            case(?text) {{body = (Text.encodeUtf8(text)); headers = [("Content-Type", "image/svg+xml")]; streaming_strategy = null; status_code = 200;}};
        };
    };

///////////////////////////////////////////////////////////////

    ///////////
    // ADMIN //
    ///////////

///////////////////////////////////////////////////////////////

    let dfx_identity_principal_isaac : Principal = Principal.fromText("ijeuu-g4z7n-jndij-hzfqh-fe2kw-7oan5-pcmgj-gh3zn-onsas-dqm7c-nqe");
    let plug_principal_isaac : Principal = Principal.fromText("gj3h2-k3kw2-ciszt-6zylp-azl7o-mvg5j-eudtf-fpejf-mx2rd-ifsul-dqe");
    let plug_principal_seb : Principal = Principal.fromText("udmjf-fyc6j-f7dnl-dw5bh-hh4wg-ln7iy-36pgp-mjocm-my4vc-r2irg-2ae");

    var admins : [Principal] = [dfx_identity_principal_isaac, plug_principal_isaac, plug_principal_seb]; 

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
        };

    };

    // building SVG
    private func _build_svg(graduate : Graduate) : Text {
        var holder_title = "The Owner Of This NFT";
        
        if (graduate.preference == 1) {
            holder_title := graduate.name;
        } else if (graduate.preference == 2) {
            holder_title := graduate.username;
        } else if (graduate.preference == 3) {
            holder_title := "The Owner Of This NFT";
        };

        var content : Text = "";
        content := svg_art[0] # graduate.track;
        content := content # svg_art[1] # graduate.date;
        content := content # svg_art[2] # graduate.desc2;
        content := content # svg_art[3] # graduate.status;
        content := content # svg_art[4] # holder_title;
        content := content # svg_art[5] # graduate.desc1 # svg_art[6];

        return content;
    };

    private func _getTokenByPrincipal(principal : Principal) : ?Nat {
        for (key in owners.keys()) {
            if (_isOwner(principal, key)) {
                return ?key;
            };
        };

        return null;
    };

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

// End of construction area

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

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

    private func _isOwner(caller : Principal, tokenId : T.TokenId) : Bool {
        switch(_ownerOf(tokenId)) {
            case(null) return false;
            case(?x) {
                if (caller == x) {
                    return true;
                } else {
                    return false;
                };
            };
        };
    };

    private func _tokenURI(tokenId : T.TokenId) : ?Text {
        return tokenURIs.get(tokenId);
    };

    private func _replace_uri(graduate : Graduate, tokenId : T.TokenId) {
        let new_uri : Text = _build_svg(graduate);

        graduates.put(tokenId, graduate);
        tokenURIs.put(tokenId, new_uri);
    };

    private func _getEntries() : [(T.TokenId, Principal)] {
        Iter.toArray(owners.entries());
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
        // assert Option.unwrap(_ownerOf(tokenId)) == from;

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

    private func _mint(to : Principal, tokenId : Nat, graduate : Graduate) : () {
        assert not _exists(tokenId);
        let uri : Text = _build_svg(graduate);

        _incrementBalance(to);
        owners.put(tokenId, to);        
        tokenURIs.put(tokenId,uri);
        graduates.put(tokenId, graduate);
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
        graduateEntries := Iter.toArray(graduates.entries());
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
        graduateEntries := [];
    };

};