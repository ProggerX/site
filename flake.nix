{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils, ... }:
	flake-utils.lib.eachDefaultSystem (system:
	let pkgs = nixpkgs.legacyPackages.${system};
	in {
		packages.default = pkgs.stdenv.mkDerivation {
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
		nixosModules.default = { config, lib, ... }: {
			options = {
				server.site.enable = lib.mkEnableOption "Enable ProggerX's site";
			};
			config = lib.mkIf config.server.site.enable {
				containers.site = {
					autoStart = true;
					privateNetwork = true;
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
						system.stateVersion = "24.05";
						systemd.services.site = {
							wantedBy = [ "multi-user.target "];
							serviceConfig = {
								ExStart = "${self.packages.default}/bin/site";
							};
						};
						services.nginx = {
							enable = true;
							virtualHosts.site = {
								addSSL = true;
								enableACME = true;
								serverName = "_";
								locations."/" = {
									proxyPass = "http://0.0.0.0:8005";
								};
							};
						};
						security.acme = {
							acceptTerms = true;
							defaults.email = "x@proggers.ru";
						};
					};
				};
			};
		};
	});
}
