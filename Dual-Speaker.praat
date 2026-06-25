# Sound와 TextGrid 선택 확인
sound_id = selected("Sound")
textgrid_id = selected("TextGrid")

# [설정] 화자 순서별 무음 기준값 설정
tier_number = 1
spk1_threshold = 25   ;# 첫 번째로 말하는 화자 (목소리 정상/큼)
spk2_threshold = 18   ;# 두 번째로 말하는 화자 (목소리 작음)

# 1. Sound로부터 Intensity 객체 생성
selectObject: sound_id
intensity_id = To Intensity: 100, 0, "yes"

selectObject: textgrid_id
total_intervals = Get number of intervals: tier_number

clearinfo
appendInfoLine: "[검사 시작] 대사 순서 기반 화자 추적 분석 중..."
appendInfoLine: "--------------------------------------------------"

# 대사가 있는 구간이 몇 번째로 등장했는지 세어줄 카운터 변수
speech_counter = 0

# 2. 루프 시작
for i from 1 to total_intervals
    selectObject: textgrid_id
    label$ = Get label of interval: tier_number, i
    
    # 공백 구간(빈칸)이 아니고 대사 문장이 채워져 있는 경우에만 진입
    if label$ <> ""
        # 대사가 등장할 때마다 카운트를 1씩 증가 (1, 2, 3, 4...)
        speech_counter = speech_counter + 1
        
        # 홀수 번째 대사는 첫 번째 화자, 짝수 번째 대사는 두 번째 화자로 판정
        if speech_counter mod 2 == 1
            silence_threshold = spk1_threshold
            speaker_name$ = "첫 번째 화자(큰소리)"
        else
            silence_threshold = spk2_threshold
            speaker_name$ = "두 번째 화자(작은소리)"
        endif
        
        start_time = Get start time of interval: tier_number, i
        end_time = Get end time of interval: tier_number, i
        
        # 2-1. 앞쪽 무음 길이 측정
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
        
        # 2-2. 뒤쪽 무음 길이 측정
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
        
        # 2-3. 조건 검사 (0.2초 이상 0.5초 이하가 아니면 불합격 출력)
        front_fail = (front_silence < 0.2 or front_silence > 0.5)
        back_fail = (back_silence < 0.2 or back_silence > 0.5)
        
        if front_fail or back_fail
            appendInfoLine: "❌ [불합격] ", i, "번째 구간: 『", label$, "』"
            appendInfoLine: "   - 추정 화자: ", speaker_name$, " [적용 기준: ", silence_threshold, "dB]"
            if front_fail
                appendInfoLine: "   - 앞쪽 무음: ", round(front_silence*1000)/1000, "초"
            endif
            if back_fail
                appendInfoLine: "   - 뒤쪽 무음: ", round(back_silence*1000)/1000, "초"
            endif
            appendInfoLine: "   -----------------------------------------------"
        endif
    endif
endfor

appendInfoLine: "[검사 완료]"

selectObject: intensity_id
Remove
selectObject: sound_id, textgrid_id
