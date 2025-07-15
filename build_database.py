import json
import os

def save_recipes_to_json(recipes: list, filename: str = 'recipes.json'):
    """레시피 딕셔너리 리스트를 JSON 파일로 저장합니다."""
    try:
        # 스크립트가 실행되는 위치를 기준으로 프로젝트 루트에 상대적인 경로인지 확인합니다.
        # 또는 필요한 경우 절대 경로를 처리합니다.
        full_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
        
        with open(full_path, 'w', encoding='utf-8') as f:
            json.dump(recipes, f, ensure_ascii=False, indent=2)
        print(f"성공적으로 {len(recipes)}개의 레시피를 {full_path}에 저장했습니다.")
    except Exception as e:
        print(f"레시피를 JSON으로 저장하는 중 오류 발생: {e}")

if __name__ == "__main__":
    # 이 부분은 AI가 추출할 실제 데이터의 플레이스홀더입니다.
    # 이 스크립트를 실행할 때, 추출된 데이터를 save_recipes_to_json에 전달해야 합니다.
    # 시연을 위해 샘플 레시피가 포함되어 있습니다.
    sample_recipes = [
        {
            "name": "샘플 레시피",
            "description": "AI가 추출한 샘플 레시피입니다.",
            "ingredients": ["샘플 재료1", "샘플 재료2"],
            "cooking_time": 10,
            "cost": 1000,
            "tags": ["샘플", "테스트"],
            "instructions": ["샘플 조리법 1", "샘플 조리법 2"],
            "source_url": "http://example.com/sample"
        }
    ]
    save_recipes_to_json(sample_recipes)