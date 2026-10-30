# ci/props.py <header> <fct>: one -wp-prop selection per line; together they cover every goal of fct.
import re, sys
lines = open(sys.argv[1]).read().split('\n')
start = next(i for i, l in enumerate(lines) if l.startswith(sys.argv[2] + '('))
end = next(i for i in range(start, len(lines)) if lines[i] == '}')
names = re.findall(r'loop invariant ([A-Za-z_][A-Za-z0-9_]*):', '\n'.join(lines[start:end]))
if len(set(names)) != len(names): sys.exit('duplicate invariant name in ' + sys.argv[2])
cats = ['@ensures', '@assert', '@requires', '@assigns']
for x in names + cats: print(x)
print(','.join('-' + x for x in names + cats))
