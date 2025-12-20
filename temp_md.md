ok since this problem is solved now next problem. in the file folder view @beautifulMentionwhole page is rerendered when any folder card is clicked since whole page comes in the route and for entering into a folder we need to change the route and thus whole page is removed and new page is rerendered or redrawn. but I want that the header and the "Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t
                          .t('files_total_items')
                          .replaceAll(
                            '{count}',
                            (folders.length + files.length).toString(),
                          ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                tooltip: t.t('files_sort_filter_tooltip'),
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilterDialog(),
              ),
              IconButton(
                onPressed: () {
                  showNewFolderSheet(
                    context: context,
                    onCreate: (String folderName) async {
                      if (_currentPath == null || folderName.trim().isEmpty)
                        return;
                      await context.read<FileSystemProvider>().createFolder(
                        _currentPath!,
                        folderName,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
            ],
          ),
        ),
        " section of the top which tells which is the current folder and the items number in it with few folder and filtering featues in it. these things should not get redrawn everytime I enter a folder or comes out of it. their value like the folder name and content count should be updated thats it. for this I want you to make the page wrap within another layout which will contain the header and this folder above overview. and also manage its routing config. routing in the @beautifulMentionyou have to maintain it such that the 