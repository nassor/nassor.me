all:
	@ hugo --theme=liquorice
	@ rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress public/* root@nassor.me:/var/www/nassor/
