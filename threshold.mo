import {Array_tabulate; Array_init; call_raw; debugPrint; principalOfActor; nat64ToNat; time = nanos1970} = "mo:⛔";

actor class(signers : [Principal]) = threshold {
    type Id = Nat;
    type Timestamp = Nat;
    type Payload = (Principal, Text, Blob);
    type Vote = (Timestamp, Principal);
    type State = (Bool, Nat, Nat, [Vote], ?Blob);
    type Prop = { id : Id; memo : Text; var state : State; payload : Payload };

    stable var serial = 0;
    stable var authorised : [Principal] = do {
        assert signers.size() > 1;
        // no duplicates allowed
        let good = Array_init<?Principal>(signers.size(), null);
        var occup = 0;
        for (s0 in signers.vals()) {
            let s = ?s0;
            var j = 0;
            while (j < occup) {
                assert s != good[j];
                j += 1
            };
            good[occup] := s;
            occup += 1
        };
        signers
    };
    stable var proposals : [Prop] = [];

    public shared ({caller}) func submit(memo : Text, payload : Payload) : async Nat {
        authorise caller;
        serial += 1;
        let ?votes = vote(caller, []);
        proposals := prepend<Prop>({ id = serial; memo; var state = (true, 1, 0, votes, null); payload }, proposals);
        serial
    };

    public shared ({caller}) func accept(id : Id) : async () {
        authorise caller;
        for (prop in proposals.vals()) {
            let { id = i; payload } = prop;
            let (active, yes, no, votes, res) = prop.state;
            switch (vote(caller, votes)) {
                case null ();
                case (?votes) {
                    if (id == i and active) {
                        prop.state := (active, yes + 1, no, votes, res);
                        func passing((_, yes, no, _, _) : State) : Bool = 2 * yes > authorised.size(); // FIXME!
                        if (passing(prop.state)) { /*do not*/ await execute(prop, payload) };
                        return
                    }
                }
            }
        };
    };

    public shared ({caller}) func reject(id : Id) : async () {
        authorise caller;
        for (prop in proposals.vals()) {
            let { id = i; payload = (principal, method, blob) } = prop;
            let (active, yes, no, votes, res) = prop.state;
            switch (vote(caller, votes)) {
                case null ();
                case (?votes) {
                    if (id == i and active) {
                        func hopeless((_, yes, no_pre, _, _) : State) : Bool {
                            let signers = authorised.size();
                            let no = no_pre + 1;
                            2 * no > signers or yes + no >= signers
                        };
                        prop.state := (not hopeless(prop.state), yes, no + 1, votes, res);
                        return
                    }
                }
            }
        }
    };

    public shared ({caller}) func prune() : async () {
        self caller;
        proposals := filter(func (p : Prop) : Bool = p.state.0, proposals)
    };

    public shared ({caller}) func set_signers(authlist : [Principal]) : async () {
        self caller;
        authorised := sanitiseSigners authlist
    };

    public shared query ({caller}) func get_signers() : async [Principal] {
        authorise caller;
        authorised
    };

    type Proposal = { id : Id; memo : Text; state : State; payload : Payload };
    // authorised principals can retrieve proposals
    public shared query ({caller}) func get_proposals() : async [Proposal] {
        authorise caller;
        Array_tabulate<Proposal>(proposals.size(), func n = { proposals[n] with state = proposals[n].state })
    };

    public shared query ({caller}) func get_proposal(id : Id) : async ?Proposal {
        authorise caller;
        for (p in proposals.vals()) {
            if (p.id == id) return ?{ p with state = p.state }
        };
        null
    };

    // traps when p is not in the `authorised` list
    func authorise(p : Principal) {
        for (a in authorised.vals()) {
            if (p == a) return
        };
        debug {
            debugPrint(debug_show ("cannot authorise", p))
        };
        assert false;
    };

    // traps when p is not this actor
    func self(p : Principal) {
        assert p == principalOfActor threshold
    };

    func execute(prop : Prop, (principal, method, blob) : Payload) : async () {
        prop.state := (false, prop.state.1, prop.state.2, prop.state.3, prop.state.4);
        // send the payload
        switch (is_selfupgrade(principal, method, blob)) {
            case (?params) {
                     debug debugPrint(debug_show ("it's a selfupgrade", params));
                     let ic00 = actor "aaaaa-aa" :
                                actor { install_code : InstallParams -> () };
                     ic00.install_code params
                 };
            case _ {
                let res = await call_raw(principal, method, blob);
                prop.state := (prop.state.0, prop.state.1, prop.state.2, prop.state.3, ?res);
            }
        }
    };

    // utilities
    func prepend<A>(a : A, as : [A]) : [A] =
        Array_tabulate<A>(as.size() + 1, func i = if (i == 0) a else as[i - 1]);

    func filter<A>(p : A -> Bool, as : [A]) : [A] {
        var hits = 0;
        let good = Array_init<?A>(as.size(), null);
        for (a in as.vals()) {
            if (p(a)) { good[hits] := ?a; hits += 1 };
        };
        Array_tabulate<A>(hits, func(i) : A { let ?h = good[i]; h });
    };

    // helpers
    type InstallParams = {
        mode : { #install; #reinstall; #upgrade };
        canister_id : Principal;
        wasm_module : Blob;
        arg : Blob;
    };
    func is_selfupgrade((addressee, method, args) : Payload) : ?InstallParams {
        if (addressee == principalOfActor (actor "aaaaa-aa") and method == "install_code") {
            do ? {
                let params : InstallParams = (from_candid(args) : ?InstallParams)!;
                if (params.canister_id == principalOfActor threshold)
                   params
                   else null!
            }
        } else null
    };

    func now() : Timestamp = nat64ToNat(nanos1970()) / 1_000_000_000; // seconds since 1970-01-01

    func vote(signer : Principal, votes : [Vote]) : ?[Vote] {
        for ((_, p) in votes.vals()) {
            if (p == signer) return null;
        };
        ?prepend((now(), signer), votes);
    };

    func sanitiseSigners(signers : [Principal]) : [Principal] {
        assert signers.size() > 1;
        // no duplicates allowed
        let good = Array_init<?Principal>(signers.size(), null);
        var occup = 0;
        for (s0 in signers.vals()) {
            let s = ?s0;
            var j = 0;
            while (j < occup) {
                assert s != good[j];
                j += 1
            };
            good[occup] := s;
            occup += 1
        };
        signers
    }
}
