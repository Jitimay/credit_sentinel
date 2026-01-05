import re
import os
import json
from abc import ABC, abstractmethod
from typing import List, Dict, Any
import google.generativeai as genai
from tenacity import retry, stop_after_attempt, wait_fixed

# --- Abstract Strategy ---
class ExtractionStrategy(ABC):
    @abstractmethod
    def extract(self, text: str) -> List[Dict[str, Any]]:
        pass

# --- Regex Strategy (Legacy/Fallback) ---
class RegexStrategy(ExtractionStrategy):
    def extract(self, text: str) -> List[Dict[str, Any]]:
        covenants = []
        
        # Pattern 1: Leverage Ratio (Debt/EBITDA)
        leverage_match = re.search(r"(?i)(leverage|debt\s?to\s?ebitda|net\s?debt).*?(\d+\.?\d*)x?", text)
        if leverage_match:
            covenants.append({
                "name": "Debt-to-EBITDA",
                "threshold": float(leverage_match.group(2)),
                "operator": "<=",
                "category": "Financial"
            })
            
        # Pattern 2: Interest Coverage
        ic_match = re.search(r"(?i)(interest\s?coverage).*?(\d+\.?\d*)", text)
        if ic_match:
            covenants.append({
                "name": "Interest Coverage",
                "threshold": float(ic_match.group(2)),
                "operator": ">=",
                "category": "Financial"
            })

        # Pattern 3: Current Ratio
        cr_match = re.search(r"(?i)(current\s?ratio).*?(\d+\.?\d*)", text)
        if cr_match:
            covenants.append({
                "name": "Current Ratio",
                "threshold": float(cr_match.group(2)),
                "operator": ">=",
                "category": "Financial"
            })
            
        return covenants

# --- LLM Strategy (Gemini) ---
class LLMStrategy(ExtractionStrategy):
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')

    @retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
    def extract(self, text: str) -> List[Dict[str, Any]]:
        prompt = f"""
        Extract all financial covenants from the following loan agreement text.
        Return a JSON array where each object has:
        - name: str (e.g. "Debt-to-EBITDA")
        - threshold: float (the numeric limit)
        - operator: str (e.g. "<=", ">=")
        - category: str ("Financial" or "Reporting")
        - clause: str (the snippet of text where found)

        Text:
        {text[:8000]}  # Truncate to avoid context limits
        """
        response = self.model.generate_content(prompt)
        try:
            # Basic cleanup of markdown naming
            clean_json = response.text.replace("```json", "").replace("```", "")
            return json.loads(clean_json)
        except Exception as e:
            print(f"LLM Extraction Error: {e}")
            return []

# --- Context Manager ---
class CovenantEngine:
    def __init__(self, use_llm=False):
        api_key = os.getenv("GEMINI_API_KEY")
        if use_llm and api_key:
            self.strategy = LLMStrategy(api_key)
        else:
            self.strategy = RegexStrategy()

    def extract_covenants(self, text: str):
        return self.strategy.extract(text)

    def evaluate(self, covenant: Dict[str, Any], current_value: float):
        # ... (Evaluation logic remains similar)
        thresh = covenant["threshold"]
        op = covenant["operator"]
        
        status = "Compliant"
        if op == "<=" and current_value > thresh:
            status = "Breach"
        elif op == ">=" and current_value < thresh:
            status = "Breach"
        elif op == "<=" and current_value > (thresh * 0.9):
            status = "Warning"
        elif op == ">=" and current_value < (thresh * 1.1):
            status = "Warning"
            
        return {
            "status": status,
            "current_value": current_value,
            "threshold": thresh
        }

    def generate_explanation(self, covenant: Dict[str, Any], result: Dict[str, Any]):
        # ... (Use existing explanation logic)
        status = result["status"]
        name = covenant["name"]
        val = result["current_value"]
        thresh = result["threshold"]
        op = covenant["operator"]
        
        if status == "Breach":
            return (f"CRITICAL BREACH DETECTED: The borrower's {name} of {val} has significantly violated the {op} {thresh} threshold. "
                    "Immediate action required.")
        elif status == "Warning":
            distance = round(abs(val - thresh) / thresh * 100, 1)
            return (f"EARLY WARNING: The {name} ratio is currently {val}, sitting only {distance}% away from the {thresh} limit.")
        else:
            return f"COMPLIANT: The {name} ratio of {val} is safe."
