# Sound와 TextGrid가 동시에 선택되어 있는지 확인
sound_id = selected("Sound")
textgrid_id = selected("TextGrid")

# 설정 값 (환경에 맞게 조절 가능)
silence_threshold = 20  ;# 무음으로 판단할 Intensity 임계값 (dB)
tier_number = 1         ;# 텍스트그리드의 레이어 번호

# 1. Sound로부터 Intensity 객체 생성
selectObject: sound_id
intensity_id = To Intensity: 100, 0, "yes"

# 2. TextGrid의 총 구간 수 가져오기
selectObject: textgrid_id
total_intervals = Get number of intervals: tier_number

# 결과 출력을 위한 초기화
clearinfo
appendInfoLine: "[검사 시작] 총 ", total_intervals, "개 구간 분석 중..."
appendInfoLine: "--------------------------------------------------"

# 3. 모든 구간을 하나씩 돌면서 검사 (Loop)
for i from 1 to total_intervals
    selectObject: textgrid_id
    label$ = Get label of interval: tier_number, i
    
    # 공백 구간(빈칸)이 아니고, 텍스트가 채워져 있는 경우에만 검사 진행
    if label$ <> ""
        start_time = Get start time of interval: tier_number, i
        end_time = Get end time of interval: tier_number, i
        
        # 3-1. 앞쪽 무음 길이 측정
        selectObject: intensity_id
        current_time = start_time
        front_silence = 0
        while current_time < end_time
            val = Get value at time: current_time, "Cubic"
            if val == undefined or val < silence_threshold
                front_silence = front_silence + 0.01
                current_time = current_time + 0.01
            else
                goto FRONT_DONE
            endif
        endwhile
        label FRONT_DONE
        
        # 3-2. 뒤쪽 무음 길이 측정
        current_time = end_time
        back_silence = 0
        while current_time > start_time
            val = Get value at time: current_time, "Cubic"
            if val == undefined or val < silence_threshold
                back_silence = back_silence + 0.01
                current_time = current_time - 0.01
            else
                goto BACK_DONE
            endif
        endwhile
        label BACK_DONE
        
        # 3-3. 조건 검사 (0.2초 이상 0.5초 이하가 아니면 불합격 출력)
        front_fail = (front_silence < 0.2 or front_silence > 0.5)
        back_fail = (back_silence < 0.2 or back_silence > 0.5)
        
        if front_fail or back_fail
            appendInfoLine: "❌ [불합격] ", i, "번째 구간 ('", label$, "')"
            if front_fail
                appendInfoLine: "   - 앞쪽 무음: ", round(front_silence*1000)/1000, "초 (범위 이탈)"
            endif
            if back_fail
                appendInfoLine: "   - 뒤쪽 무음: ", round(back_silence*1000)/1000, "초 (범위 이탈)"
            endif
            appendInfoLine: "   -----------------------------------------------"
        endif
    endif
endfor

appendInfoLine: "[검사 완료]"

# 사용한 임시 Intensity 객체 삭제
selectObject: intensity_id
Remove
selectObject: sound_id, textgrid_id
