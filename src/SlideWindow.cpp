// Leetcode 567. 字符串的排列: 给你两个字符串 s1 和 s2 ，写一个函数来判断 s2 是否包含 s1 的排列。如果是，返回true；否则返回false。换句话说，s1的排列之一是s2的子串 。
// https://leetcode.cn/problems/permutation-in-string?envType=problem-list-v2&envId=rRP85rzQ

#include <string>
#include <unordered_map>

class Solution {
public:
    void InitTarget(const std::string& str_target) {
        len_target_ = str_target.size();
        for (const auto& ch : str_target) {
            map_target_[ch]++;
        }
    }

    void PushRight(const char& ch) {
        if (map_target_.contains(ch)) {
            if (map_cur_[ch]++ < map_target_[ch]) {
                ready_cnt_++;
            }
        }
    }

    void PopLeft(const char& ch) {
        if (map_target_.contains(ch)) {
            if (map_cur_[ch]-- <= map_target_[ch]) {
                ready_cnt_--;
            }
        }
    }

    bool IsValid() const { return ready_cnt_ == len_target_; }

    bool checkInclusion(const std::string& s1, const std::string& s2) {
        InitTarget(s1);

        // 扩大窗口：尝试寻找符合条件的子串
        for (int left = 0, right = 0; right < s2.size();) {
            PushRight(s2[right++]); // 扩大窗口

            // 收缩窗口
            while (right - left >= len_target_) {
                // 验证当前窗口是否符合条件
                if (IsValid()) {
                    return true;
                }

                PopLeft(s2[left++]);
            }
        }
        return false;
    }

private:
    std::unordered_map<char, int> map_target_; // 目标频率表
    std::unordered_map<char, int> map_cur_;    // 当前窗口频率表
    int ready_cnt_ = 0;                        // 满足频率条件的字符数
    int len_target_ = 0;                       // 目标长度
};
