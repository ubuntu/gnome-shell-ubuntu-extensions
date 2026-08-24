i18n = import('i18n')

gettext_domain = run_command(
  jq,
  '-r',
  '."gettext-domain"',
  metadata,
  check: true,
).stdout().strip()

i18n.gettext(
  gettext_domain,
  preset: 'glib',
  install: false,
)
