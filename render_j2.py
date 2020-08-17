#!/usr/bin/env python3

import jinja2

import itertools
import math
import sys

def find_q(i, n):
    x = i
    if (x%2) == 0:
        x -= 1
    chosen = []
    while len(chosen) < n:
        if all(math.gcd(a, x) == 1 for a in chosen):
            chosen.append(x)
        x -= 2
    return chosen

def test():
    print(find_q(0x10000, 10))

def main(argv):
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath="./templates/"),
        keep_trailing_newline=True,
        )

    ways = 10
    search_size_bytes = 2*1024*1024
    search_size_elements = search_size_bytes >> 5
    qval = find_q(search_size_elements, ways+1)
    ctx = {}
    ctx["deg_f"] = 4
    ctx["p"] = qval[0]
    del qval[0]
    ctx["q"] = qval

    template = env.get_template("KnsTokenWork.sol.j2")

    rendered = template.render(ctx)
    rendered = rendered.lstrip()

    try:
        with open("contracts/KnsTokenWork.sol", "r") as f:
            current_contract = f.read()
    except Exception:
        current_contract = ""
    if rendered != current_contract:
        with open("contracts/KnsTokenWork.sol", "w") as f:
            f.write(rendered)

if __name__ == "__main__":
    main(sys.argv)
