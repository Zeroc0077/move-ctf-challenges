set -eux

cd framework-solve/solve && aptos move compile
cd ..
python3 solve.py
