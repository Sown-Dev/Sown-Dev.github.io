# Updating https://sown-dev.github.io/

This folder is the repo `Sown-Dev/Sown-Dev.github.io`; GitHub Pages serves `main` as the home page.

- **Publish:** run `publish.ps1` (or double-click `publish.cmd`). It looks for any of your public repos with Pages turned on that aren't listed yet (and actually load), adds them to `sites.json`, rebuilds the list in `index.html`, commits and pushes. Live about a minute later.
  - `-Message "text"` commit message, `-NoDiscover` skip the GitHub lookup, `-NoPush` rebuild locally only.
- **Add or change an entry by hand:** `.\add-site.ps1 <path> "Name" "Description"` links `https://sown-dev.github.io/<path>/`; add `-Url <address>` to link anywhere else, `-Hide` to keep it off the page (discovery won't re-add it), `-Remove` to drop it.
- **The list itself** is `sites.json` (`path`, `name`, `description`, optional `url`, `hidden`); the rest of the page is plain `index.html`: edit anything outside the `<ul class="sites">` block freely.
- Each subfolder site (`/hub/`, `/fixtools/`, ...) is its own repo with Pages on; this repo only links to them.
