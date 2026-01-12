resource "aws_bedrock_guardrail" "main" {
  name                      = var.guardrail_name
  blocked_input_messaging   = "I cannot answer that question as it violates our content policy."
  blocked_outputs_messaging = "I cannot provide that type of information."
  description              = var.description

  # Content Policy Configuration - Filter harmful content
  content_policy_config {
    filters_config {
      type            = "VIOLENCE"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "HATE"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
  }

  # Topic Policy Configuration - Deny legal and medical advice
  topic_policy_config {
    topics_config {
      name       = "Legal Advice"
      definition = "Questions seeking legal advice, legal interpretation, or legal counsel regarding travel documents, visas, regulations, rights, obligations, or legal consequences."
      examples = [
        "Can I sue if my Mars visa is denied?",
        "What are my legal rights if I'm detained on Mars?",
        "Is this travel policy legally binding?",
        "Can I take legal action against the Mars immigration office?"
      ]
      type = "DENY"
    }
    topics_config {
      name       = "Medical Advice"
      definition = "Questions seeking medical advice, health recommendations, diagnosis, or treatment guidance related to travel health, medical conditions, medications, or health risks."
      examples = [
        "What vaccines do I need for Mars travel?",
        "Can I travel to Mars with a heart condition?",
        "What medication should I take for radiation exposure?",
        "How do I treat altitude sickness on Mars?"
      ]
      type = "DENY"
    }
  }

  tags = var.tags
}
