#include <vector>
#include <iostream>
#include <algorithm>
#include <deque>

using namespace std;

vector<int> nums  = {};
vector<int> track = {};
vector<bool> used = {};

// 形式一、元素无重可复选，即 nums
// 中的元素都是唯一的，每个元素可以被使用若干次，只要删掉去重逻辑即可，backtrack 核心代码如下：

// 组合/子集问题回溯算法框架
void backtrack(vector<int>& nums, int start, deque<int>& track)
{
  // 回溯算法标准框架
  for (int i = start; i < nums.size(); i++)
  {
    // 做选择
    track.push_back(nums[i]);
    // 注意参数
    backtrack(nums, i, track);
    // 撤销选择
    track.pop_back();
  }
}

// 排列问题回溯算法框架
void backtrack(vector<int>& nums, deque<int>& track)
{
  for (int i = 0; i < nums.size(); i++)
  {
    // 做选择
    track.push_back(nums[i]);
    backtrack(nums, track);
    // 撤销选择
    track.pop_back();
  }
}

// 形式二、元素无重不可复选，即 nums 中的元素都是唯一的，每个元素最多只能被使用一次，
// backtrack核心代码如下：

// 组合/子集问题回溯算法框架
void backtrack(vector<int>& nums, int start)
{
  // 回溯算法标准框架
  for (int i = start; i < nums.size(); i++)
  {
    // 做选择
    track.push_back(nums[i]);
    // 注意参数
    backtrack(nums, i + 1);
    // 撤销选择
    track.pop_back();
  }
}

// 排列问题回溯算法框架
void backtrack(vector<int>& nums)
{
  for (int i = 0; i < nums.size(); i++)
  {
    // 剪枝逻辑
    if (used[i])
    {
      continue;
    }
    // 做选择
    used[i] = true;
    track.push_back(nums[i]);
    backtrack(nums);
    // 撤销选择
    track.pop_back();
    used[i] = false;
  }
}

// 形式三、元素可重不可复选，即 nums
// 中的元素可以存在重复，每个元素最多只能被使用一次，其关键在于排序和剪枝，backtrack 核心代码如下：

sort(nums.begin(), nums.end());
// 组合/子集问题回溯算法框架
void backtrack(vector<int>& nums, int start)
{
  // 回溯算法标准框架
  for (int i = start; i < nums.size(); i++)
  {
    // 剪枝逻辑，跳过值相同的相邻树枝
    if (i > start && nums[i] == nums[i - 1])
    {
      continue;
    }
    // 做选择
    track.push_back(nums[i]);
    // 注意参数
    backtrack(nums, i + 1);
    // 撤销选择
    track.pop_back();
  }
}

sort(nums.begin(), nums.end());
// 排列问题回溯算法框架
void backtrack(vector<int>& nums, vector<bool>& used)
{
  for (int i = 0; i < nums.size(); i++)
  {
    // 剪枝逻辑
    if (used[i])
    {
      continue;
    }
    // 剪枝逻辑，固定相同的元素在排列中的相对位置
    if (i > 0 && nums[i] == nums[i - 1] && !used[i - 1])
    {
      continue;
    }
    // 做选择
    used[i] = true;
    track.push_back(nums[i]);

    backtrack(nums, used);
    // 撤销选择
    track.pop_back();
    used[i] = false;
  }
}
