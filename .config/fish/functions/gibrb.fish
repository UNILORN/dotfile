function gibrb
        git branch --show-current | gsed 's/.*\///g' | read -d '' BRANCH;
        open https://redmine.tokyo.optim.co.jp/iot/issues/$BRANCH
end
