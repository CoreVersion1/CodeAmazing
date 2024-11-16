#include <iostream>
#include <vector>

class DoublyListNode {
 public:
  DoublyListNode(int val) : val(val), prev(nullptr), next(nullptr) {}

 public:
  int val              = {};
  DoublyListNode* prev = {};
  DoublyListNode* next = {};
};

class solution {
 public:
  // 数组创建双向链表
  DoublyListNode* CreateDoublyLinkedList(const std::vector<int>& arr)
  {
    if (arr.empty())
    {
      return nullptr;
    }

    DoublyListNode* head = new DoublyListNode(arr[0]);
    DoublyListNode* cur  = head;
    for (int i = 1; i < arr.size(); ++i)
    {
      auto* new_node = new DoublyListNode(arr[i]);
      new_node->prev = cur;
      cur->next      = new_node;
      cur            = cur->next;
    }

    return head;
  }

  // 遍历双向链表-从头节点向后遍历
  void TraverseDoublyLinkdedList(DoublyListNode* head)
  {
    for (auto* cur = head; cur != nullptr; cur = cur->next)
    {
      std::cout << cur->val << " ";
    }
    std::cout << std::endl;
  }

  // 遍历双向链表-从尾节点向前遍历
  void TraverseDoublyLinkedListReverse(DoublyListNode* head)
  {
    auto* cur = head;
    while (cur->next != nullptr)
    {
      cur = cur->next;
    }
    auto* tail = cur;

    for (auto* cur = tail; cur != nullptr; cur = cur->prev)
    {
      std::cout << cur->val << " ";
    }
    std::cout << std::endl;
  }

  DoublyListNode* AddHead(DoublyListNode* head, int val)
  {
    auto* new_node = new DoublyListNode(val);
    if (head == nullptr)
    {
      head = new_node;
      return head;
    }

    new_node->next = head;
    head->prev     = new_node;
    head           = new_node;
    return head;
  }

  DoublyListNode* AddTail(DoublyListNode* head, int val)
  {
    auto* new_node = new DoublyListNode(val);

    auto* cur = head;
    while (cur->next != nullptr)
    {
      cur = cur->next;
    }
    auto* tail = cur;

    // 添加到尾部
    new_node->prev = tail;
    tail->next     = new_node;
    tail           = new_node;

    return head;
  }

  DoublyListNode* AddMid(DoublyListNode* head, int val, int pos)
  {
    auto* new_node = new DoublyListNode(val);
    auto* cur      = head;
    for (int i = 0; i < pos - 1; ++i)
    {
      if (cur != nullptr)
      {
        cur = cur->next;
      }
    }

    // 修改新节点的前后指针
    new_node->prev = cur;
    new_node->next = cur->next;
    // 修改前节点的next指针
    cur->next = new_node;
    // 修改后节点的prev指针
    cur->next->prev = new_node;

    return head;
  }

  DoublyListNode* DelListNode(DoublyListNode* head, int idx)
  {
    auto* cur = head;
    for (int i = 0; i < idx - 1; i++)
    {
      if (cur != nullptr)
      {
        cur = cur->next;
      }
    }

    if (cur == nullptr || cur->next == nullptr)
    {
      return head;
    }
    auto* to_del = cur->next;

    // 修改前后项的指针
    cur->next          = to_del->next;
    to_del->next->prev = cur;
    // 清理节点的前后指针
    to_del->next = nullptr;
    to_del->prev = nullptr;

    return head;
  }

  DoublyListNode* DelHead(DoublyListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }
    auto* to_del = head;

    // 修改head指针
    head = head->next;
    // 修改前后项的指针
    head->prev = nullptr;

    // 清理节点的前后指针
    to_del->next = nullptr;

    return head;
  }

  DoublyListNode* DelTail(DoublyListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }

    auto* cur = head;
    while (cur->next != nullptr)
    {
      cur = cur->next;
    }
    auto* to_del = cur;

    // 修改前后项的指针
    cur->prev->next = nullptr;
    // 清理节点的前后指针
    to_del->prev = nullptr;

    return head;
  }
};

int main(void)
{
  std::cout << "CreateDoublyLinkedList: " << std::endl;
  std::vector<int> arr = {1, 2, 3, 4, 5};
  auto* head           = solution().CreateDoublyLinkedList(arr);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "AddHead: " << std::endl;
  head = solution().AddHead(head, 0);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "AddTail: " << std::endl;
  head = solution().AddTail(head, 6);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "AddMid: " << std::endl;
  head = solution().AddMid(head, 7, 3);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "DelListNode: " << std::endl;
  head = solution().DelListNode(head, 3);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "DelHead: " << std::endl;
  head = solution().DelHead(head);
  solution().TraverseDoublyLinkdedList(head);

  std::cout << "DelTail: " << std::endl;
  head = solution().DelTail(head);
  solution().TraverseDoublyLinkdedList(head);

  return 0;
}
