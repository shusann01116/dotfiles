{ config, lib, ... }:

let
  # Eval-time enumeration reads the flake's store copy: only git-tracked
  # files appear. New agents/skills must be `git add`ed to get linked.
  claudeRepo = ../../package/claude;
  link = rel: config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/package/claude/${rel}";

  entriesIn = dir:
    lib.attrNames (lib.filterAttrs (_: t: t == "regular" || t == "directory") (builtins.readDir dir));

  linksFor = sub:
    lib.optionalAttrs (builtins.pathExists (claudeRepo + "/${sub}")) (
      lib.listToAttrs (map
        (name: {
          name = "claude/${sub}/${name}";
          value = { source = link "${sub}/${name}"; };
        })
        (entriesIn (claudeRepo + "/${sub}")))
    );
in
{
  # ~/.config/claude stays a real directory: local-only agents, skills,
  # daemon state, and session data coexist with these repo-managed links.
  xdg.configFile = lib.mkMerge [
    {
      "claude/settings.json".source = link "settings.json";
      "claude/CLAUDE.md".source = link "CLAUDE.md";
    }
    (linksFor "agents")
    (linksFor "scripts")
    (linksFor "hooks")
    (linksFor "skills")
  ];
}
