function gibr
       	git remote get-url origin | sed -e 's/ssh:\/\/git@/https:\/\//g' -e 's/:11022//g' -e 's/\.git//g' | xargs -I {} open {}
end
