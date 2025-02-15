# Configuration for Home-Managers programs.git options
{ lib, pkgs }:
{
  enable = true;
  ignores = [
    "**/.*.swp"
    "**/__pycache__"
    ".idea"
  ];
  aliases = {
    # git auf deutsch
    eroeffne = "init";
    machnach = "clone";
    zieh = "pull";
    fueghinzu = "add";
    drueck = "push";
    pfusch = "push";
    zweig = "branch";
    verzweige = "branch";
    uebergib = "commit";
    erde = "rebase";
    unterscheide = "diff";
    vereinige = "merge";
    bunkere = "stash";
    markiere = "tag";
    nimm = "checkout";
    tagebuch = "log";
    zustand = "status";
  };
  extraConfig = {
    user = {
      name = "lilly";
      email = "li@lly.sh";
      signingkey = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPohjBYcg4GR9hKH6vdT5V2OA+rpTBkDOJZzipnotpR+ li@lly.sh";
    };
    core = {
      autocrlf = "input";
      fscache = true;
    };
    alias = {
      ldog = "log --all --decorate --oneline --graph";
    };
    pull.rebase = true;
    color.ui = "auto";
    init.defaultBranch = "main";
    push.autoSetupRemote = true;
    gpg.format = "ssh";
    gpg.ssh.allowedSignersFile = "${pkgs.writeText "trusted-git-signers" ''
      li@lly.sh,dev@ftsell.de ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPohjBYcg4GR9hKH6vdT5V2OA+rpTBkDOJZzipnotpR+
    ''}";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
  includes =
    let
      vcaConfig = {
        user = {
          name = "ftsell";
          email = "f.sell@vivaconagua.org";
        };
      };
      b1Config = {
        user = {
          name = "Lilly Sell";
          email = "sell@b1-systems.de";
        };
      };
      cccConfig = {
        user = {
          name = "lilly";
          email = "ccc@lly.sh";
        };
      };
    in
    [
      {
        condition = "hasconfig:remote.origin.url:git@github.com/viva-con-agua/**";
        contents = vcaConfig;
      }
      {
        condition = "hasconfig:remote.origin.url:https://github.com/viva-con-agua/**";
        contents = vcaConfig;
      }
      {
        condition = "hasconfig:remote.origin.url:forgejo@git.hamburg.ccc.de:*/**";
        contents = cccConfig;
      }
      {
        condition = "hasconfig:remote.origin.url:https://git.hamburg.ccc.de/**";
        contents = cccConfig;
      }
      {
        condition = "gitdir:~/Projects/mafiasi/py_simple_openid_connect/*";
        contents = b1Config;
      }
      {
        condition = "gitdir:~/Projects/b1/**";
        contents = b1Config;
      }
    ];
}
