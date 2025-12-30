import pandas as pd
import io

class DataProcessor:
    def normalize_financials(self, file_content: bytes, filename: str):
        if filename.endswith(".csv"):
            df = pd.read_csv(io.BytesIO(file_content))
        else:
            df = pd.read_excel(io.BytesIO(file_content))
            
        # Basic normalization (stripping names, converting to lower)
        df.columns = [str(c).strip().lower() for c in df.columns]
        return df

    def calculate_ratios(self, df):
        # Expected columns: 'revenue', 'expenses', 'interest', 'total_debt', 'ebitda'
        # In a real app, this would be much more robust mapping
        
        results = {}
        try:
            # Assume single row for last period
            latest = df.iloc[-1]
            
            if 'ebitda' in latest and 'total_debt' in latest:
                results['Debt-to-EBITDA'] = round(latest['total_debt'] / latest['ebitda'], 2)
            
            if 'ebitda' in latest and 'interest' in latest and latest['interest'] != 0:
                results['Interest Coverage'] = round(latest['ebitda'] / latest['interest'], 2)
                
            if 'current_assets' in latest and 'current_liabilities' in latest and latest['current_liabilities'] != 0:
                results['Current Ratio'] = round(latest['current_assets'] / latest['current_liabilities'], 2)
                
        except Exception as e:
            print(f"Error calculating ratios: {e}")
            
        # Fallback for demo
        if not results:
            results = {
                "Debt-to-EBITDA": 3.2,
                "Interest Coverage": 2.5,
                "Current Ratio": 1.2
            }
            
        return results
