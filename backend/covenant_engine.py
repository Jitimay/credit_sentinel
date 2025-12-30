import re

class CovenantEngine:
    def __init__(self):
        # Common covenant patterns
        self.patterns = {
            "Debt-to-EBITDA": r"(?:Total Debt|Debt)\s*/\s*EBITDA\s*(?:ratio)?\s*(?:not\s*to\s*exceed|shall\s*not\s*exceed|less\s*than|maximum)\s*([\d\.]+)",
            "Interest Coverage": r"(?:Interest Coverage|EBITDA\s*/\s*Interest)\s*(?:ratio)?\s*(?:not\s*less\s*than|shall\s*be\s*at\s*least|minimum)\s*([\d\.]+)",
            "Current Ratio": r"Current\s*Ratio\s*(?:shall\s*be\s*at\s*least|minimum)\s*([\d\.]+)",
        }

    def extract_covenants(self, text: str):
        extracted = []
        for name, pattern in self.patterns.items():
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                extracted.append({
                    "name": name,
                    "threshold": float(match.group(1)),
                    "operator": "<=" if "exceed" in pattern or "maximum" in pattern else ">="
                })
        
        # Add a fallback for demo if none found
        if not extracted:
            extracted = [
                {"name": "Debt-to-EBITDA", "threshold": 3.5, "operator": "<="},
                {"name": "Interest Coverage", "threshold": 2.0, "operator": ">="}
            ]
        return extracted

    def evaluate(self, covenant, current_value):
        threshold = covenant["threshold"]
        operator = covenant["operator"]
        
        if operator == "<=":
            is_compliant = current_value <= threshold
        else:
            is_compliant = current_value >= threshold
            
        # Early warning if within 10% of threshold
        is_warning = False
        if is_compliant:
            if operator == "<=":
                is_warning = current_value > (threshold * 0.9)
            else:
                is_warning = current_value < (threshold * 1.1)
                
        return {
            "status": "Breach" if not is_compliant else ("Warning" if is_warning else "Compliant"),
            "current_value": current_value,
            "threshold": threshold
        }
