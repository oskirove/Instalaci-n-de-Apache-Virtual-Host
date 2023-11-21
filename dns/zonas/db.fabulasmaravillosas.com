$TTL 38400	; 10 hours 40 minutes
@		IN SOA	ns.fabulasmaravillosas.com. info@fabulasmaravillosas.com. (
				10000002   ; serial
				10800      ; refresh (3 hours)
				3600       ; retry (1 hour)
				604800     ; expire (1 week)
				38400      ; minimum (10 hours 40 minutes)
				)
@		IN NS	ns.fabulasmaravillosas.com.
ns		IN A		192.168.1.5
www		IN A		192.168.1.2
alias	IN CNAME	www
texto	IN TXT		"Hola mundo"