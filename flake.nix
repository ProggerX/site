{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs, ... }:
	let system = "aarch64-linux";
	pkgs = nixpkgs.legacyPackages.${system};
	in {
		packages."${system}".default = pkgs.stdenv.mkDerivation {
			name = "site";
			src = ./.;
			buildInputs = with pkgs; [
				boost.dev
			];
			nativeBuildInputs = with pkgs; [
				gcc
			];
			buildPhase = ''g++ ./src/main.cpp -I./include -o out'';
			installPhase = ''mkdir -p $out/bin && mv ./out $out/bin/site'';
		};
		nixosModules.site = { config, lib, ... }: {
			options = {
				server.site.enable = lib.mkEnableOption "Enable ProggerX's site";
			};
			config = lib.mkIf config.server.site.enable {
				containers.site = {
					autoStart = true;
					privateNetwork = true;
					hostAddress = "192.168.1.248";
					localAddress = "192.168.1.249";
					forwardPorts = [
						{
							hostPort = 80;
							containerPort = 80;
						}
						{
							hostPort = 443;
							containerPort = 443;
						}
					];
					config = {
						services.resolved.enable = true;
						networking.useHostResolvConf = lib.mkForce false;
						system.stateVersion = "24.05";
						systemd.services.site = {
							wantedBy = [ "multi-user.target" ];
							serviceConfig = {
								ExStart = "${self.packages."${system}".default}/bin/site";
							};
						};
						services.nginx = {
							enable = true;
							virtualHosts.site = {
								addSSL = true;
								enableACME = true;
								serverName = "proggers.ru";
								locations."/" = {
									proxyPass = "http://0.0.0.0:8005";
								};
							};
						};
						security.acme = {
							acceptTerms = true;
							defaults.email = "x@proggers.ru";
						};
						networking.firewall.allowedTCPPorts = [ 80 443 ];
					};
				};
			};
		};
	};
}
