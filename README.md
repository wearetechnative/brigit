# brigit


**B**ranch **I**ntegrity **G**uard for **Git**

<img src="images/brigitlogo.png" style="width:200px" />


CLI tool voor het beheren van GitHub branch protection rules.

## Vereisten

- `gh` - GitHub CLI (authenticated)
- `jq` - JSON processor
- `gum` - Terminal UI toolkit

## Gebruik

```bash
# Toon help
brigit

# Scan repositories op branch protection compliance
brigit scan -o <organization>                    # Alle repos in org
brigit scan -o <organization> -r <repository>   # Specifieke repo

# Enforce branch protection
brigit enforce -o <organization> -r <repository>  # Specifieke repo
brigit enforce -f repos-20260226_123456.txt       # Vanuit file

# Opruimen van log files
brigit clean                                      # Verwijder alle log/repos files
```

## Workflow

```bash
# 1. Scan een organisatie
brigit scan -o mijn-org

# 2. Bekijk resultaten in brigit-scan-*.log

# 3. Enforce protection op repos met issues
brigit enforce -f repos-20260226_123456.txt

# 4. Controleer of alles is opgelost
brigit scan -o mijn-org
```

## Output bestanden

| Bestand | Beschrijving |
|---------|--------------|
| `brigit-scan-yyyymmdd_uummss.log` | Scan resultaten |
| `brigit-enforce-yyyymmdd_uummss.log` | Enforce resultaten |
| `repos-yyyymmdd_uummss.txt` | Repos met issues (alleen aangemaakt als er issues zijn) |

Het `repos-*.txt` bestand bevat repos in het formaat `org:repo` en kan direct als input voor `brigit enforce -f` worden gebruikt.

## Configuratie

Branch protection instellingen staan in `ghbranchprotection.json`:

```json
{
  "default": {
    "required_pull_request_reviews": {
      "required_approving_review_count": 1
    }
  }
}
```

## Branch protection checks

brigit controleert of:
- Pull request vereist is voor mergen naar main
- Minimaal 1 approval vereist is
