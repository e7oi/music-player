#!/usr/bin/env bash
# Contrôles de cohérence du dépôt (job `repo-checks` de docs-ci).
# Exécute tous les contrôles, puis sort avec un code ≠ 0 si l'un d'eux a échoué.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Empreinte SHA-256 du texte officiel de la GPL v3 (relevée au Sprint 1).
LICENSE_SHA256="3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"

failures=0
fail() {
  echo "ERREUR : $*" >&2
  failures=$((failures + 1))
}
ok() {
  echo "OK     : $*"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# 1. Fichiers et dossiers attendus.
missing=0
for f in LICENSE README.md PRD.md CHANGELOG.md HOWTO.md; do
  if [ ! -f "$f" ]; then
    fail "fichier manquant à la racine : $f"
    missing=1
  fi
done
if [ ! -d docs/sprints ]; then
  fail "dossier manquant : docs/sprints/"
  missing=1
fi
[ "$missing" -eq 0 ] && ok "fichiers et dossier attendus présents"

# 2. LICENSE = texte officiel de la GPL v3.
if [ -f LICENSE ]; then
  actual="$(sha256_of LICENSE)"
  if [ "$actual" = "$LICENSE_SHA256" ]; then
    ok "LICENSE conforme à la GPL v3 officielle (SHA-256 $actual)"
  else
    fail "LICENSE modifiée : SHA-256 $actual, attendu $LICENSE_SHA256"
  fi
fi

# 3. README : licence et titulaire du copyright.
if [ -f README.md ]; then
  readme_ok=1
  for needle in "GPL-3.0-or-later" "Eloi BERTIN"; do
    if ! grep -q -F "$needle" README.md; then
      fail "README.md ne contient pas « $needle »"
      readme_ok=0
    fi
  done
  [ "$readme_ok" -eq 1 ] && ok "README.md mentionne GPL-3.0-or-later et Eloi BERTIN"
fi

# 4. « Dernière MAJ » datée dans PRD.md et CHANGELOG.md.
date_re='Dernière MAJ[^0-9]*([0-9]{2}/[0-9]{2}/[0-9]{4}|[0-9]{4}-[0-9]{2}-[0-9]{2})'
for f in PRD.md CHANGELOG.md; do
  [ -f "$f" ] || continue
  if grep -q -E "$date_re" "$f"; then
    ok "$f contient une ligne « Dernière MAJ » datée"
  else
    fail "$f : aucune ligne « Dernière MAJ » avec une date (JJ/MM/AAAA ou AAAA-MM-JJ)"
  fi
done

# 5. Aucun fichier suivi indésirable (système, IDE, clés).
forbidden_re='(^|/)\.DS_Store$|(^|/)\.idea/|\.iml$|\.(jks|keystore|p12|pem)$|(^|/)key\.properties$'
tracked_bad="$(git ls-files | grep -E "$forbidden_re" || true)"
if [ -n "$tracked_bad" ]; then
  fail "fichiers suivis interdits (.DS_Store, .idea/, *.iml, clés ou keystores) :"
  printf '%s\n' "$tracked_bad" | sed 's/^/         /' >&2
else
  ok "aucun fichier suivi interdit"
fi

# 6. RESULTS.md et DIAGNOSTICS.md vivent dans docs/sprints/sprint-1/ : aucun
#    document à la racine ne doit les référencer comme s'ils étaient à la racine.
bad_refs=""
for f in $(git ls-files | grep -v '/' | grep -E '\.md$' || true); do
  hits="$(grep -n -o -E '[A-Za-z0-9_./-]*(RESULTS|DIAGNOSTICS)\.md' "$f" \
    | grep -v -E ':docs/sprints/' || true)"
  if [ -n "$hits" ]; then
    bad_refs="$bad_refs$(printf '%s\n' "$hits" | sed "s|^|$f:|")
"
  fi
done
if [ -n "$bad_refs" ]; then
  fail "référence à RESULTS.md ou DIAGNOSTICS.md sans chemin docs/sprints/ dans un document racine :"
  printf '%s' "$bad_refs" | sed 's/^/         /' >&2
else
  ok "aucune référence à RESULTS.md ou DIAGNOSTICS.md à la racine"
fi

if [ "$failures" -ne 0 ]; then
  echo "$failures contrôle(s) en échec." >&2
  exit 1
fi
echo "Tous les contrôles sont passés."
