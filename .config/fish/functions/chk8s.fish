function chk-dev
	sh ~/infra_secret/assume/dev.sh yusuke.aoki@optim.co.jp | source
	export KUBECONFIG=$HOME/infra_secret/primary-kubeconfig_dev.yaml	
end

function chk-prod
	sh ~/infra_secret/assume/prod.sh yusuke.aoki@optim.co.jp | source
        export KUBECONFIG=$HOME/infra_secret/primary-kubeconfig_prod.yaml
end
