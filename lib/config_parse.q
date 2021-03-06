\d .utl
configParsing:((),`)!enlist (::)

configParsing.stripComments:{[l];l where not any l like/: (";*";"#*")}
configParsing.stripEmptyLines:{[l];l where not "" ~/: configParsing.trim[" \t"] l}
/ Regular trim functions only handle spaces
configParsing.ltrim:{$[not type y;.z.s[x] each y;any x = first y;(sum scan[and] over[or] x=\:y)_ y;y]}
configParsing.rtrim:{$[not type y;.z.s[x] each y;any x = last y;reverse configParsing.ltrim[x] reverse y;y]}
configParsing.trim:{configParsing.ltrim[x] configParsing.rtrim[x] y}

configParsing.sections:{[fn;l];
  cl:count l;
  p:where (rtrim each l) like "[[]*]"; / Left square brackets can't simply be escaped
  if[not count p;'"There were no sections found in the file: '",fn,"'"];
  sectionNames:(1 _ -1 _ rtrim @) each l p;
  sectionNames!l (p cut til count l) except\: p / Cut in such a way as to return only the lines in each section
  }
  
configParsing.pairs:{[fn;l];
  n:where any l like\:/: ("*:*";"*=*");
  if[not 0 in n;'"There was an improperly formatted line in the file: '",fn,"'"];
  badLines: where not (l (til count l) except n) like "[ \t]*";
  if[count badLines;'"There was an improperly formatted line in the file: '",fn,"'";];
  l:raze each n cut l;
  nPos: {min raze x ss/: "=:"} each l;
  d:flip (0,'nPos) cut' l;
  d[0]: configParsing.trim[" \t"] each d[0];
  d[1]: (configParsing.ltrim[" \t"] 1 _) each d[1];
  d:(!) . d;
  if[any "" ~/: key d;'"There was an empty key in the file: '",fn,"'";];
  dk!reverse[d] dk:distinct key d
  }

configParsing.substituteLine:{[d;l];
  pred:(p[0] < p[1]) and 2 = count p: first flip l ss/: ("%(";")s");
  if[() ~ pred;:l]; / If there are no substitution characters, p is an empty list and the normal predicate doesn't work right
  $[pred;
    $[(lookup:2 _ (pieces:(0,p) cut l) 1) in key d;
      .z.s[d;pieces[0],d[lookup],2 _ pieces 2];
      not "" ~ e:getenv `$lookup;
      .z.s[d;pieces[0],e,2 _ pieces 2];
      l
      ];
    l / The substitution strings were in the wrong order or there was only one and there was no substitution to perform
    ]
  }

parseRawConfig:{[file];
  l:$[-11h ~ type file;[fn:1 _ string file;read0 file];[fn:"input string";file]];
  l:configParsing.stripEmptyLines configParsing.stripComments l;
  configParsing.pairs[fn] each configParsing.sections[fn] l
  }

parseConfig:{[file];
  cfg:parseRawConfig[file];
  {configParsing.substituteLine[d] each d:x,y}[cfg["DEFAULT"]] each enlist["DEFAULT"] _ cfg
  }
