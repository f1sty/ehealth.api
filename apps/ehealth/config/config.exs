use Mix.Config

# General application configuration
config :ehealth,
  env: Mix.env(),
  namespace: EHealth,
  ecto_repos: [EHealth.Repo, EHealth.PRMRepo, EHealth.FraudRepo, EHealth.EventManagerRepo],
  run_declaration_request_terminator: true,
  system_user: {:system, "EHEALTH_SYSTEM_USER", "4261eacf-8008-4e62-899f-de1e2f7065f0"},
  sensitive_data_in_response: {:system, :boolean, "SENSITIVE_DATA_IN_RESPONSE_ENABLED", false},
  api_resolvers: [
    man: EHealth.API.Man,
    mpi: EHealth.API.MPI,
    mithril: EHealth.API.Mithril,
    digital_signature: EHealth.API.Signature,
    ops: EHealth.API.OPS,
    report: EHealth.API.Report,
    media_storage: EHealth.API.MediaStorage,
    otp_verification: EHealth.API.OTPVerification,
    postmark: EHealth.API.Postmark,
    uaddresses: EHealth.API.UAddress
  ],
  cache: [
    validators: EHealth.Validators.Cache
  ]

# Config Jason as default Json encoder for Phoenix and Ecto
config :phoenix, :format_encoders, json: Jason
config :ecto, json_library: Jason

# Configures the endpoint
config :ehealth, EHealth.Web.Endpoint,
  url: [
    host: "localhost"
  ],
  secret_key_base: "AcugHtFljaEFhBY1d6opAasbdFYsvV8oydwW98qS0oZOv+N/a5TE5G7DPfTZcXm9",
  render_errors: [
    view: EView.Views.PhoenixError,
    accepts: ~w(json)
  ]

# Configures Digital Signature API
config :ehealth, EHealth.API.Signature,
  enabled: {:system, :boolean, "DIGITAL_SIGNATURE_ENABLED", true},
  endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MediaStorage API
config :ehealth, EHealth.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET"},
  contract_request_bucket: {:system, "MEDIA_STORAGE_CONTRACT_REQUEST_BUCKET"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET"},
  medication_request_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false},
  hackney_options: [
    connect_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures PRM API
config :ehealth, EHealth.API.PRM,
  endpoint: {:system, "PRM_ENDPOINT", "http://api-svc.prm/api"},
  hackney_options: [
    connect_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Legal Entities token permission
config :ehealth, EHealth.Plugs.ClientContext,
  tokens_types_personal: {:system, :list, "TOKENS_TYPES_PERSONAL", ["MSP", "PHARMACY"]},
  tokens_types_mis: {:system, :list, "TOKENS_TYPES_MIS", ["MIS"]},
  tokens_types_admin: {:system, :list, "TOKENS_TYPES_ADMIN", ["NHS ADMIN"]},
  tokens_types_cabinet: {:system, :list, "TOKENS_TYPES_CABINET", ["CABINET"]}

# Configures OAuth API
config :ehealth, EHealth.API.Mithril,
  endpoint: {:system, "OAUTH_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Man API
config :ehealth, EHealth.API.Man,
  endpoint: {:system, "MAN_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000}
  ]

# Configures UAddress API
config :ehealth, EHealth.API.UAddress,
  endpoint: {:system, "UADDRESS_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OTP Verification API
config :ehealth, EHealth.API.OTPVerification,
  endpoint: {:system, "OTP_VERIFICATION_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MPI API
config :ehealth, EHealth.API.MPI,
  endpoint: {:system, "MPI_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OPS API
config :ehealth, EHealth.API.OPS,
  endpoint: {:system, "OPS_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Report API
config :ehealth, EHealth.API.Report,
  endpoint: {:system, "REPORT_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000}
  ]

# configure emails
config :ehealth, :emails,
  default: %{
    format: {:system, "TEMPLATE_FORMAT", "text/html"},
    locale: {:system, "TEMPLATE_LOCALE", "uk_UA"}
  },
  employee_request_invitation: %{
    from: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_SUBJECT", ""}
  },
  employee_request_update_invitation: %{
    from: {:system, "BAMBOO_EMPLOYEE_REQUEST_UPDATE_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_REQUEST_UPDATE_INVITATION_SUBJECT", ""}
  },
  hash_chain_verification_notification: %{
    from: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_FROM", ""},
    to: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_TO", ""},
    subject: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_SUBJECT", ""}
  },
  employee_created_notification: %{
    from: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_SUBJECT", ""}
  },
  credentials_recovery_request: %{
    from: {:system, "BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_SUBJECT", ""}
  }

config :ehealth, EHealth.Man.Templates.EmployeeRequestInvitation,
  id: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

# Configures employee request update invitation template
config :ehealth, EHealth.Man.Templates.EmployeeRequestUpdateInvitation,
  id: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, EHealth.Man.Templates.HashChainVerificationNotification,
  id: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_ID", ""},
  format: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_FORMAT", ""},
  locale: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_LOCALE", ""}

# employee created notification
# Configures employee created notification template
config :ehealth, EHealth.Man.Templates.EmployeeCreatedNotification,
  id: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, EHealth.Man.Templates.DeclarationRequestPrintoutForm,
  id: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID"},
  format: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, EHealth.Man.Templates.ContractRequestPrintoutForm,
  id: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID"},
  format: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, EHealth.Man.Templates.EmailVerification,
  id: {:system, "EMAIL_VERIFICATION_TEMPLATE_ID"},
  from: {:system, "EMAIL_VERIFICATION_FROM"},
  subject: {:system, "EMAIL_VERIFICATION_SUBJECT"},
  format: {:system, "EMAIL_VERIFICATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMAIL_VERIFICATION_TEMPLATE_LOCALE", "uk_UA"}

# Template and setting for credentials recovery requests
config :ehealth, :credentials_recovery_request_ttl, {:system, :integer, "CREDENTIALS_RECOVERY_REQUEST_TTL", 1_500}

config :ehealth, EHealth.Man.Templates.CredentialsRecoveryRequest,
  id: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID"},
  format: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, :legal_entity_employee_types,
  msp: {:system, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN"]},
  pharmacy: {:system, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST", "HR"]}

config :ehealth, :legal_entity_division_types,
  msp: {:system, "LEGAL_ENTITY_MSP_DIVISION_TYPES", ["CLINIC", "AMBULANT_CLINIC", "FAP"]},
  pharmacy: {:system, "LEGAL_ENTITY_PHARMACIST_DIVISION_TYPES", ["DRUGSTORE", "DRUGSTORE_POINT"]}

config :ehealth, :employee_specialities_types,
  doctor:
    {:system, "DOCTOR_SPECIALITIES_TYPES",
     [
       "1.083",
       "1.118",
       "1.074",
       "1.104",
       "1.123",
       "1.067",
       "1.043",
       "1.034",
       "1.005",
       "1.120",
       "1.022",
       "1.008",
       "4.008",
       "1.105",
       "1.080",
       "1.075",
       "1.099",
       "1.045",
       "1.064",
       "1.112",
       "1.096",
       "1.035",
       "1.060",
       "1.087",
       "4.009",
       "1.012",
       "1.013",
       "1.110",
       "1.109",
       "1.006",
       "1.114",
       "5.002",
       "2.003",
       "5.001",
       "1.070",
       "1.102",
       "5.006",
       "1.091",
       "1.052",
       "4.010",
       "1.068",
       "1.033",
       "4.002",
       "1.004",
       "1.020",
       "1.007",
       "1.036",
       "1.024",
       "1.010",
       "5.010",
       "1.077",
       "1.041",
       "1.050",
       "1.061",
       "1.046",
       "5.007",
       "1.038",
       "1.051",
       "1.056",
       "1.085",
       "1.098",
       "1.055",
       "1.015",
       "1.082",
       "1.016",
       "1.047",
       "1.081",
       "2.004",
       "5.005",
       "1.062",
       "1.095",
       "1.089",
       "1.028",
       "1.029",
       "1.107",
       "3.001",
       "1.094",
       "1.106",
       "1.059",
       "5.003",
       "1.040",
       "5.004",
       "1.039",
       "1.011",
       "1.018",
       "1.023",
       "1.001",
       "1.117",
       "1.069",
       "5.009",
       "1.101",
       "1.113",
       "1.021",
       "1.037",
       "1.058",
       "4.012",
       "1.063",
       "1.057",
       "1.093",
       "1.071",
       "1.092",
       "1.122",
       "1.030",
       "1.026",
       "1.044",
       "1.002",
       "1.090",
       "1.066",
       "1.079",
       "1.025",
       "4.005",
       "1.097",
       "4.004",
       "5.008",
       "1.111",
       "1.065",
       "1.115",
       "2.001",
       "1.086",
       "1.019",
       "1.088",
       "1.042",
       "4.011",
       "2.002",
       "4.013",
       "1.027",
       "4.003",
       "1.084",
       "1.053",
       "1.103",
       "1.116",
       "1.073",
       "1.003",
       "1.121",
       "1.054",
       "1.009",
       "4.006",
       "1.108",
       "1.017",
       "1.014",
       "1.049",
       "4.014",
       "4.007",
       "4.001",
       "1.124",
       "1.032",
       "1.078",
       "1.072",
       "1.048",
       "1.031",
       "1.076",
       "1.119",
       "1.100"
     ]},
  pharmacist: {:system, "PHARMACIST_SPECIALITIES_TYPES", ["PHARMACIST", "PHARMACIST2"]}

config :ehealth, :medication_request_request,
  expire_in_minutes: {:system, "MEDICATION_REQUEST_REQUEST_EXPIRATION", 30},
  otp_code_length: {:system, "MEDICATION_REQUEST_REQUEST_OTP_CODE_LENGTH", 4}

config :ehealth, :medication_request,
  sign_template_sms:
    {:system, "TEMPLATE_SMS_FOR_SIGN_MEDICATION_REQUEST",
     "Ваш рецепт: <request_number>. Код підтвердження: <verification_code>"},
  reject_template_sms:
    {:system, "TEMPLATE_SMS_FOR_REJECT_MEDICATION_REQUEST", "Відкликано рецепт: <request_number> від <created_at>"}

config :ehealth, EHealth.Bamboo.Emails.Sender, mailer: {:system, :module, "BAMBOO_MAILER"}

# Configures bamboo
config :ehealth, EHealth.API.Postmark, endpoint: {:system, "POSTMARK_ENDPOINT"}

config :ehealth, EHealth.Bamboo.PostmarkMailer,
  adapter: EHealth.Bamboo.PostmarkAdapter,
  api_key: {:system, "POSTMARK_API_KEY", ""}

config :ehealth, EHealth.Bamboo.MailgunMailer,
  adapter: EHealth.Bamboo.MailgunAdapter,
  api_key: {:system, "MAILGUN_API_KEY", ""},
  domain: {:system, "MAILGUN_DOMAIN", ""}

config :ehealth, EHealth.Bamboo.SMTPMailer,
  adapter: EHealth.Bamboo.SMTPAdapter,
  server: {:system, "BAMBOO_SMTP_SERVER", ""},
  hostname: {:system, "BAMBOO_SMTP_HOSTNAME", ""},
  port: {:system, "BAMBOO_SMTP_PORT", ""},
  username: {:system, "BAMBOO_SMTP_USERNAME", ""},
  password: {:system, "BAMBOO_SMTP_PASSWORD", ""},
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  ssl: true,
  retries: 1

# Configures address merger
config :ehealth, EHealth.Utils.AddressMerger, no_suffix_areas: {:system, "NO_SUFFIX_AREAS", ["М.КИЇВ", "М.СЕВАСТОПОЛЬ"]}

# Configures genral validator
config :ehealth, EHealth.LegalEntities.Validator, owner_positions: {:system, :list, "OWNER_POSITIONS", [""]}

# Configures birth date validator
config :ehealth, EHealth.Validators.BirthDate,
  min_age: {:system, "MIN_AGE", 0},
  max_age: {:system, "MAX_AGE", 150}

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :ehealth, EHealth.Scheduler,
  declaration_request_autotermination:
    {:system, :string, "DECLARATION_REQUEST_AUTOTERMINATION_SCHEDULE", "* 0-4 * * *"},
  employee_request_autotermination: {:system, :string, "EMPLOYEE_REQUEST_AUTOTERMINATION_SCHEDULE", "0-4 * * *"}

config :ehealth, EHealth.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 1000}

# Configures Cabinet
config :ehealth, jwt_secret: {:system, "JWT_SECRET"}

config :ehealth, EHealth.Cabinet.API,
  # hour
  jwt_ttl_email: {:system, :integer, "JWT_TTL_EMAIL"},
  jwt_ttl_registration: {:system, :integer, "JWT_TTL_REGISTRATION"},
  role_id: {:system, "CABINET_ROLE_ID"},
  client_id: {:system, "CABINET_CLIENT_ID"}

# Configures Guardian
config :ehealth, EHealth.Guardian,
  issuer: "EHealth",
  secret_key: {Confex, :fetch_env!, [:ehealth, :jwt_secret]}

config :cipher,
  keyphrase: System.get_env("CIPHER_KEYPHRASE") || "8()VN#U#_CU#X)*BFG(Cadsvn$&",
  ivphrase: System.get_env("CIPHER_IVPHRASE") || "B((%(^(%V(CWBY(**(by(*YCBDYB#(Y(C#"

import_config "#{Mix.env()}.exs"
