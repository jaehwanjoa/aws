사전 요구 조건
		a. SSO 사용자 권한: Identity Center 사용
		
			- AmazonAthenaFullAccess
			- AmazonGuardDutyFullAccess_v2
			- AWSConfigUserAccess
			- AWSSecurityHubReadOnlyAccess
			- AWSWAFFullAccess
ReadOnlyAccess
<img width="1414" height="1626" alt="image" src="https://github.com/user-attachments/assets/a9ebd7af-f658-46d9-b1f6-f8a6c4324728" />

SSO 프로파일 설정
		SSO URL 확인
		<img width="1818" height="828" alt="image" src="https://github.com/user-attachments/assets/673e7715-1ed0-4250-890e-3f9c567a3152" />
		aws configure sso
		<img width="867" height="204" alt="image" src="https://github.com/user-attachments/assets/a7e80fbd-bb4a-4d05-9766-d9e8b3271325" />
		인증 및 계정 선택
		<img width="561" height="239" alt="image" src="https://github.com/user-attachments/assets/305f5558-60ec-4a22-a53a-80fc6a9fb781" />
		역할 선택
		<img width="407" height="95" alt="image" src="https://github.com/user-attachments/assets/737c0b6f-7afd-40d7-926f-4dea8133b89f" />
		프로파일 이름 입력(필수)
		<img width="796" height="77" alt="image" src="https://github.com/user-attachments/assets/14fd7db7-867f-4914-a3ec-50ca006b89dd" />

사용 메뉴얼
	SSO 로그인: aws sso login --profile ons-waf
	프로파일 권한 확인: aws sts get-caller-identity --profile ons-waf
	테라폼 시작: terraform init
	테라폼 적용: terraform apply
	작업 종료: aws sso logout

Region 변경(요구조건이 서울 이외인 경우)
	terraform
	└─ envs
	   ├─ cloudfront
	   │  ├─ provider.tf
	   │  ├─ variables.tf
	   │  ├─ production.tf   
	   │  └─ terraform.tfvars #CloudFront용 WAF WebACL Name 및 S3 경로 지정
	   └─ regional
	      ├─ production.tf 싱가폴 리전 Alias 변경
	      ├─ provider.tf 싱가폴 리전 변경
	      ├─ variables.tf
	      ├─ terraform.tf      
	      └─ terraform.tfvars #Regional용 WAF WebACL Name 및 S3 경로 지정
	
	modules
	└─ waf
	   ├─ main.tf #메인 실행 파일 
   └─ variables.tf

Terraform 폴더 구조
	terraform
	└─ envs
	   ├─ cloudfront
	   │  ├─ provider.tf
	   │  ├─ variables.tf
	   │  ├─ production.tf   
	   │  └─ terraform.tfvars #CloudFront용 WAF WebACL Name 및 S3 경로 지정
	   └─ regional
	      ├─ provider.tf
	      ├─ variables.tf
	      ├─ terraform.tf      
	      └─ terraform.tfvars #Regional용 WAF WebACL Name 및 S3 경로 지정
	
	modules
	└─ waf
	   ├─ main.tf #메인 실행 파일 
   └─ variables.tf

폴더 설명
	#terraform > envs > cloudfront > production.tf
리전 요구사항이 있는 경우에만, 아래와 같이 수정 필요
<img width="391" height="343" alt="image" src="https://github.com/user-attachments/assets/f201c6ec-61d5-4572-bb4e-ba45e06e9ee7" />

	#terraform > envs > cloudfront > provider.tf
리전 요구사항이 있는 경우에만, 아래와 같이 수정 필요
<img width="450" height="446" alt="image" src="https://github.com/user-attachments/assets/c6b952ca-bc60-4611-9e18-0a05b5f7adf6" />

	#terraform > envs > cloudfront > terraform.tfvars
WAF 로그를 저장할 S3 버킷 ARN 입력 필요  
<img width="617" height="136" alt="image" src="https://github.com/user-attachments/assets/5279bc0d-cc28-4cdf-a345-1cdeb523427c" />

	#terraform > modules > waf > main.tf
WAF IP Sets 정보 입력
<img width="1415" height="753" alt="image" src="https://github.com/user-attachments/assets/bcadaad7-05b0-41c7-b374-0482b7a1c317" />

	WAF Regex Pattern Sets 입력
  <img width="1408" height="1182" alt="image" src="https://github.com/user-attachments/assets/86e52c10-cd83-4fc0-96e1-2319304ab1ea" />

  WAF Rule Group 정보 입력 (Rule Group에 IP Sets, Regex Pattern Set 이 포함된 구조)
<img width="1452" height="1516" alt="image" src="https://github.com/user-attachments/assets/ffa12c5c-6448-4c04-b26e-3430c410335d" />

	WAF Web ACL 생성 (IP Sets, Managed Rule 내용 삽입)
<img width="1399" height="1524" alt="image" src="https://github.com/user-attachments/assets/66007ff3-cc40-4a91-b663-90d56da2e6b8" />

	AWS WAF 로깅 설정
<img width="1406" height="338" alt="image" src="https://github.com/user-attachments/assets/214f078a-452e-4ae0-b1bd-12b17afa8406" />











