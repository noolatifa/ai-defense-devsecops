# [GATEWAY] This entire file is new - Security Gateway module

import json
from typing import Dict, Any
import os
from groq import Groq

class SecurityGateway:
    def __init__(self):
        self.allowed_email_domains = ["internal-corp.com"]
        self._groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self._guard_model = "meta-llama/llama-prompt-guard-2-86m"




    def intercept_tool_call(self, tool_name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        print(f"\n[GATEWAY] Intercepting tool call: {tool_name}")
        print(f"[GATEWAY] Parameters: {json.dumps(parameters, indent=2)}")

        if tool_name == "send_email":
            return self._validate_email(parameters)
        
        print("[GATEWAY] Action authorized.")
        return {"status": "allowed", "message": "Tool call approved"}

    def _validate_email(self, params: Dict[str, Any]) -> Dict[str, Any]:
        to_address = params.get("to", "").lower()
        subject = params.get("subject", "").lower()
        body = params.get("body", "").lower()

        domain_allowed = any(to_address.endswith(f"@{domain}") for domain in self.allowed_email_domains)
        if not domain_allowed:
            print(f"[GATEWAY] BLOCKED: Destination '{to_address}' not in allowlist.")
            return {"status": "blocked", "reason": "Unauthorized email destination"}

        result = self._groq_client.chat.completions.create(
            model=self._guard_model,
            messages=[{"role": "user", "content": f"{subject}\n{body}"[:2000]}]
        )
        label = result.choices[0].message.content.strip().upper()
        if "MALICIOUS" in label or "INJECTION" in label:
            print(f"[GATEWAY] BLOCKED: Content flagged by classifier ({label}).")
            return {"status": "blocked", "reason": f"Suspicious content (classifier: {label})"}
        print("[GATEWAY] Email validation passed.")
        return {"status": "allowed", "message": "Email approved"}
