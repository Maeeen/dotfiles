.pragma library

// Small calculator for the launcher. It parses the expression itself, so the input never runs as code.
// Operators: + - * / % ^ and parentheses. "," is also a decimal point.
// Functions: sqrt abs round floor ceil exp ln log sin cos tan asin acos atan. Constants: pi e.
// Returns the result as a string, or "" when the expression is not complete or not valid.

const functions = {
    sqrt: Math.sqrt,
    abs: Math.abs,
    round: Math.round,
    floor: Math.floor,
    ceil: Math.ceil,
    exp: Math.exp,
    ln: Math.log,
    log: Math.log10,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    asin: Math.asin,
    acos: Math.acos,
    atan: Math.atan
};

const constants = {
    pi: Math.PI,
    e: Math.E
};

function evaluate(text) {
    const tokens = text.replace(/,/g, ".").match(/\d*\.?\d+(?:e[+-]?\d+)?|[a-z]+|\S/gi) || [];
    let pos = 0;

    const peek = () => tokens[pos];
    const next = () => tokens[pos++];
    const expect = t => {
        if (next() !== t)
            throw new Error("expected " + t);
    };

    // expression := term (("+" | "-") term)*
    function expression() {
        let v = term();
        while (peek() === "+" || peek() === "-")
            v = next() === "+" ? v + term() : v - term();
        return v;
    }

    // term := unary (("*" | "/" | "%") unary)*
    function term() {
        let v = unary();
        while (peek() === "*" || peek() === "/" || peek() === "%") {
            const op = next();
            const r = unary();
            v = op === "*" ? v * r : (op === "/" ? v / r : v % r);
        }
        return v;
    }

    // unary := ("-" | "+") unary | power. So -2^2 is -4.
    function unary() {
        if (peek() === "-") {
            next();
            return -unary();
        }
        if (peek() === "+") {
            next();
            return unary();
        }
        return power();
    }

    // power := primary ("^" unary)?, right to left: 2^3^2 is 2^9
    function power() {
        const v = primary();
        if (peek() === "^") {
            next();
            return Math.pow(v, unary());
        }
        return v;
    }

    // primary := number | "(" expression ")" | constant | function "(" expression ")"
    function primary() {
        const t = next();
        if (t === undefined)
            throw new Error("end");
        if (/^\d|^\./.test(t))
            return Number(t);
        if (t === "(") {
            const v = expression();
            expect(")");
            return v;
        }
        const name = t.toLowerCase();
        if (name in constants)
            return constants[name];
        if (name in functions) {
            expect("(");
            const v = expression();
            expect(")");
            return functions[name](v);
        }
        throw new Error("unknown " + t);
    }

    try {
        const v = expression();
        if (pos !== tokens.length || !isFinite(v))
            return "";
        // 12 significant digits hide float noise: 0.1+0.2 gives 0.3
        return String(Number(v.toPrecision(12)));
    } catch (e) {
        return "";
    }
}
