module rigged_poker::main {
    use std::debug;
    use std::vector;
    use std::signer;
    use aptos_framework::object;
    use aptos_framework::randomness;
    use aptos_framework::event;

    const PH_HIGHCARD: u64 = 1;
    const PH_PAIR: u64 = 2;
    const PH_TWOPAIR: u64 = 3;
    const PH_THREEOAK: u64 = 4;
    const PH_STRAIGHT: u64 = 5;
    const PH_FULLHOUSE: u64 = 6;
    const PH_FOUROAK: u64 = 7;
    const PH_STRAIGHTFLUSH: u64 = 8;
    
    const NUM_HANDS: u64 = 4;
    const NUM_CARDS: u64 = 20;
    const GEN_COST: u64 = 10;

    struct State has key, store, copy, drop {
        ai_hands: vector<u64>,
        player_hands: vector<u64>,
        cards: vector<u64>,
        coins: u64,
        wins: u64,
    }

    struct Win has key, store {
        solved: bool
    }

    #[event]
    struct WinEvent has drop, store {
        coins_left: u64,
    }

    #[event]
    struct DebugEvent has drop, store {
        state: State,
    }

    public entry fun initialize(sig: signer) {
        assert!(signer::address_of(&sig) == @rigged_poker, 1);
        move_to(&sig, Win { solved: false });
    }

    public entry fun create(sig: signer) {
        move_to(&sig,
            State {
                ai_hands: vector::empty(),
                player_hands: vector::empty(),
                cards: vector::empty(),
                coins: 3431,
                wins: 0,
            });
    }

    #[randomness]
    entry fun generate_ai_hand(addr: address) acquires State {
        let state = borrow_global_mut<State>(addr);
        assert!(state.coins >= GEN_COST, 1);
        state.coins = state.coins - GEN_COST;
        let new_hands = vector::empty();
        while (vector::length(&new_hands) < NUM_HANDS) {
            let ty = randomness::u64_range(PH_HIGHCARD, PH_STRAIGHTFLUSH + 1);
            //let ty = randomness::u64_range(PH_HIGHCARD, PH_STRAIGHTFLUSH);
            let hand = if (ty == PH_HIGHCARD
                || ty == PH_PAIR
                || ty == PH_THREEOAK
                || ty == PH_FOUROAK) {
                ty << 8 | randomness::u64_range(0, 13) << 4
            } else if (ty == PH_TWOPAIR || ty == PH_FULLHOUSE) {
                let a = randomness::u64_range(0, 13);
                let b = randomness::u64_range(0, 12);
                if (a <= b) {
                    b = b + 1;
                };
                if (ty == PH_TWOPAIR && a < b) {
                    let c = a;
                    a = b;
                    b = c;
                };
                ty << 8 | a << 4 | b
            } else {
                // straight or straight flush
                // 5..A
                let num = randomness::u64_range(3, 13);
                let suit = if (ty == PH_STRAIGHTFLUSH) {
                    randomness::u64_range(0, 4)
                } else { 0 };
                ty << 8 | num << 4 | suit
            };
            if (vector::contains(&new_hands, &hand)) { continue };
            vector::push_back(&mut new_hands, hand);
        };
        state.ai_hands = new_hands;
        state.player_hands = vector::empty();
    }

    fun hand_valid(hand: u64): bool {
        let ty = hand >> 8;
        let a = hand >> 4 & 0xf;
        let b = hand & 0xf;
        if (ty == PH_HIGHCARD
            || ty == PH_PAIR
            || ty == PH_THREEOAK
            || ty == PH_FOUROAK) {
            if (b != 0) {
                return false
            };
            if (!(0 <= a && a < 13)) {
                return false
            };
        } else if (ty == PH_TWOPAIR || ty == PH_FULLHOUSE) {
            if (a == b) {
                return false
            };
            if (ty == PH_TWOPAIR && a < b) {
                return false
            };
            if (!(0 <= a && a < 13)) {
                return false
            };
            if (!(0 <= b && b < 13)) {
                return false
            };
        } else if (ty == PH_STRAIGHT || ty == PH_STRAIGHTFLUSH) {
            if (!(3 <= a && a < 13)) {
                return false
            };
            if (!(0 <= b && b < 4)) {
                return false
            };
        } else {
            return false
        };
        true
    }

    fun hand_better(a: u64, b: u64): u64 {
        let aty = a >> 8;
        let bty = b >> 8;
        if (aty == bty && aty == PH_STRAIGHTFLUSH) {
            a = a >> 4 << 4;
            b = b >> 4 << 4;
        };
        if (a > b) { 1 }
        else if (a < b) { 2 }
        else { 0 }
    }

    public entry fun make_play(addr: address, player_hands: vector<u64>) acquires State {
        let state = borrow_global_mut<State>(addr);
        assert!(vector::length(&state.ai_hands) == NUM_HANDS, 2);
        assert!(vector::length(&player_hands) == NUM_HANDS, 3);
        assert!(vector::length(&state.player_hands) == 0, 4);
        let i = 0;
        let n = vector::length(&player_hands);
        while (i < n) {
            let pl_hand = *vector::borrow(&player_hands, i);
            let ai_hand = *vector::borrow(&state.ai_hands, i);
            assert!(hand_valid(pl_hand), 5);
            assert!(hand_better(pl_hand, ai_hand) == 1, 6);
            assert!(!vector::contains(&state.player_hands, &pl_hand), 17);
            vector::push_back(&mut state.player_hands, pl_hand);
            i = i + 1;
        };
    }

    fun has_hand(cards: &vector<u64>, hand: u64): bool {
        let ty = hand >> 8;
        let a = hand >> 4 & 0xf;
        let b = hand & 0xf;
        let i = 0;
        let n = vector::length(cards);
        if (ty == PH_HIGHCARD
            || ty == PH_PAIR
            || ty == PH_TWOPAIR
            || ty == PH_THREEOAK
            || ty == PH_FULLHOUSE
            || ty == PH_FOUROAK) {
            let cnta = 0;
            let cntb = 0;
            while (i < n) {
                let card = *vector::borrow(cards, i) >> 2;
                if (card == a) {
                    cnta = cnta + 1;
                };
                if (card == b) {
                    cntb = cntb + 1;
                };
                i = i + 1;
            };
            if (ty == PH_HIGHCARD) {
                if (cnta >= 1) {
                    return true
                }
            } else if (ty == PH_PAIR) {
                if (cnta >= 2) {
                    return true
                }
            } else if (ty == PH_TWOPAIR) {
                if (cnta >= 2 && cntb >= 2) {
                    return true
                }
            } else if (ty == PH_THREEOAK) {
                if (cnta >= 3) {
                    return true
                }
            } else if (ty == PH_FULLHOUSE) {
                if (cnta >= 3 && cntb >= 2) {
                    return true
                }
            } else if (ty == PH_FOUROAK) {
                if (cnta >= 4) {
                    return true
                }
            };
            return false
        } else if (ty == PH_STRAIGHT || ty == PH_STRAIGHTFLUSH) {
            if (ty == PH_STRAIGHT) {
                b = 4;
            };
            let lo = if (a >= 4) {
                a - 4
            } else { 12 };
            let j = 0;
            while (lo != a && j != 5) {
                i = 0;
                while (i < n) {
                    let card = *vector::borrow(cards, i);
                    i = i + 1;
                    let num = card >> 2;
                    let suit = card & 0x3;
                    if (b != 4 && b != suit) { continue };
                    if (num == lo) {
                        lo = (lo + 1) % 13;
                    };
                };
                j = j + 1;
            };
            if (lo == a) {
                return true
            };
        } else {
            abort 99
        };
        false
    }

    fun count_has_hands(cards: &vector<u64>, hands: &vector<u64>): u64 {
        let i = 0;
        let n = vector::length(hands);
        let count = 0;
        while (i < n) {
            let hand = *vector::borrow(hands, i);
            if (has_hand(cards, hand)) {
                count = count + 1;
            };
            i = i + 1;
        };
        count
    }

    #[randomness]
    entry fun deal_cards(addr: address) acquires State {
        let state = borrow_global_mut<State>(addr);

        assert!(vector::length(&state.ai_hands) == NUM_HANDS, 7);
        assert!(vector::length(&state.player_hands) == NUM_HANDS, 8);

        let deck = vector::empty();
        let i = 0;
        while (i < 54) {
            vector::push_back(&mut deck, i);
            i = i + 1;
        };
        while (vector::length(&state.cards) < NUM_CARDS) {
            let i = randomness::u64_range(0, vector::length(&deck));
            vector::push_back(&mut state.cards, vector::remove(&mut deck, i));
        };
    }

    entry fun buy_card(addr: address, buy: u64) acquires State {
        let state = borrow_global_mut<State>(addr);

        let n = vector::length(&state.cards);
        let cost = 10 + n * n * n;
        assert!(state.coins >= cost, 9);
        state.coins = state.coins - cost;

        vector::push_back(&mut state.cards, buy);
    }

    entry fun check_result(addr: address) acquires State, Win {
        let state = borrow_global_mut<State>(addr);
        let win = borrow_global_mut<Win>(@rigged_poker);

        assert!(vector::length(&state.ai_hands) == NUM_HANDS, 10);
        assert!(vector::length(&state.player_hands) == NUM_HANDS, 11);
        assert!(vector::length(&state.cards) >= NUM_CARDS, 12);

        event::emit<DebugEvent>(DebugEvent { state: *state, });

        let pl_has = count_has_hands(&state.cards, &state.player_hands);
        let ai_has = count_has_hands(&state.cards, &state.ai_hands);

        if (pl_has >= ai_has) {
            state.wins = state.wins + 1;
            if (state.wins >= 32) {
                win.solved = true;
                event::emit<WinEvent>(WinEvent { coins_left: state.coins, });
            };
        } else {
            state.wins = 0;
        };
        state.player_hands = vector::empty();
        state.ai_hands = vector::empty();
        state.cards = vector::empty();
    }
}
