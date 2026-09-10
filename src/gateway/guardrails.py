# Role: Validate data entering and exiting the Agent
# Defense Layer: Content filtering and PII detection


import re
from typing import Dict, Any, List
import os
from groq import Groq

class Guardrails:
    def __init__(self):
        # Patterns de détection d'injection dans les prompts
        self.injection_patterns = [
            r"ignore.*previous.*instructions",
            r"you are now.*hacker",
            r"system.*override",
            r"jailbreak",
            r"ignore.*all.*rules",
            r"pretend.*you.*are",
            r"act.*as.*if",
        ]
        
        # Patterns de détection de données sensibles (PII)
        self.pii_patterns = {
            "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
            "phone": r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b",
            "ssn": r"\b\d{3}-\d{2}-\d{4}\b",
            "credit_card": r"\b\d{4}[-]?\d{4}[-]?\d{4}[-]?\d{4}\b",
        }


        self._groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self._guard_model = "meta-llama/llama-prompt-guard-2-86m"

    # we added double verif sur les injection patterns via ai analysiss

    def _classify_with_prompt_guard(self, text: str) -> Dict[str, Any]:
        try:
            result = self._groq_client.chat.completions.create(
                model=self._guard_model,
                messages=[{"role": "user", "content": text[:2000]}]
            )
            label = result.choices[0].message.content.strip().upper()
            return {"malicious": "MALICIOUS" in label or "INJECTION" in label, "raw": label}
        except Exception as e:
            print(f"[GUARDRAILS] WARNING: classifier failed ({e}), regex-only fallback.")
            return {"malicious": False, "raw": "CLASSIFIER_ERROR"}

    
    
    
    def validate_input(self, user_prompt: str) -> Dict[str, Any]:
        """Valide le prompt utilisateur avant qu'il n'atteigne l'agent."""
        prompt_lower = user_prompt.lower()
        
        # Détection d'injection
        for pattern in self.injection_patterns:
            if re.search(pattern, prompt_lower):
                return {
                    "status": "blocked",
                    "reason": f"Injection pattern detected: {pattern}",
                    "type": "input_guardrail"
                }

        classification = self._classify_with_prompt_guard(user_prompt)
        if classification["malicious"]:
            return {
                "status": "blocked",
                "reason": f"Injection detected by classifier (label: {classification['raw']})",
                "type": "input_guardrail_ml"
            }
        
        return {"status": "allowed", "message": "Input validation passed"}

    def validate_output(self, agent_output: str) -> Dict[str, Any]:
        """Valide la sortie de l'agent avant qu'elle ne soit affichée."""
        




        # 1. On autorise les mentions d'emails internes (pour éviter les faux positifs)
        # On ne bloque que si c'est un email externe suspect ou des données ultra-sensibles
        
        sensitive_patterns = {
            "social_security_number": r"\b\d{3}-\d{2}-\d{4}\b",
            "credit_card": r"\b\d{4}[-]?\d{4}[-]?\d{4}[-]?\d{4}\b",
            "external_personal_email": r"\b[A-Za-z0-9._%+-]+@(gmail|yahoo|hotmail|evil)\.com\b"
        }
        
        for pii_type, pattern in sensitive_patterns.items():
            if re.search(pattern, agent_output, re.IGNORECASE):
                return {
                    "status": "blocked",
                    "reason": f"Sensitive data detected in output: {pii_type}",
                    "type": "output_guardrail"
                }
        
        return {"status": "allowed", "message": "Output validation passed"}




    def validate_tool_registration(self, tools: list) -> Dict[str, Any]:
        findings = []
        for t in tools:
            description = getattr(t, "description", "") or ""
            name = getattr(t, "name", str(t))
            for pattern in self.injection_patterns:
                if re.search(pattern, description.lower()):
                    findings.append({"tool": name, "pattern": pattern})
            classification = self._classify_with_prompt_guard(description)
            if classification["malicious"]:
                findings.append({"tool": name, "label": classification["raw"]})
        if findings:
            return {"status": "blocked", "reason": "Suspicious tool description(s)", "findings": findings}
        return {"status": "allowed", "message": "Tool descriptions validated"}
        