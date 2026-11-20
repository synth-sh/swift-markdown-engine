// Token forms follow https://ziglang.org/documentation/0.16.0/#Grammar.
hljs.registerLanguage("zig", function (hljs) {
  const digits = (alphabet) => `[${alphabet}](?:_?[${alphabet}])*`;
  const decimal = digits("0-9");
  const hexadecimal = digits("0-9a-fA-F");
  const number = new RegExp("\\b(?:" + [
    `0b${digits("01")}`,
    `0o${digits("0-7")}`,
    `0x${hexadecimal}(?:\\.${hexadecimal})?(?:[pP][+-]?${decimal})?`,
    `${decimal}(?:\\.${decimal})?(?:[eE][+-]?${decimal})?`,
  ].join("|") + ")\\b");
  const quotedIdentifier = /@"(?:[^"\\\n]|\\.)*"/;

  return {
    name: "Zig",
    aliases: ["zon"],
    disableAutodetect: true,
    keywords: {
      keyword: [
        "addrspace align allowzero and anyframe anytype asm break callconv catch",
        "comptime const continue defer else enum errdefer error export extern fn for",
        "if inline linksection noalias noinline nosuspend opaque or orelse packed pub",
        "resume return struct suspend switch test threadlocal try union unreachable var volatile while",
      ].join(" "),
      literal: "false null true undefined",
      type: [
        "anyerror anyopaque bool comptime_float comptime_int f16 f32 f64 f80 f128 isize noreturn type usize void",
        "c_char c_short c_ushort c_int c_uint c_long c_ulong c_longlong c_ulonglong c_longdouble",
      ].join(" "),
    },
    contains: [
      hljs.C_LINE_COMMENT_MODE,
      { scope: "string", begin: /\\\\/, end: /$/, relevance: 0 },
      hljs.QUOTE_STRING_MODE,
      hljs.APOS_STRING_MODE,
      { scope: "symbol", match: quotedIdentifier, relevance: 0 },
      { scope: "built_in", match: /@[A-Za-z_]\w*/, relevance: 0 },
      {
        match: [/\bfn\b/, /\s+/, new RegExp(`[A-Za-z_]\\w*|${quotedIdentifier.source}`)],
        scope: { 1: "keyword", 3: "title.function" },
      },
      { scope: "type", match: /\b[iu][0-9]+\b/, relevance: 0 },
      { scope: "number", match: number, relevance: 0 },
    ],
  };
});
