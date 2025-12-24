<!-- # TASK 1

```dart
StatefulShellBranch(
        navigatorKey: fileNavKey,
        routes: [
          GoRoute(
          name: AppRouteName.filesRoot,
            path: '/files',
            builder: (context, state) => AndroidFilesScreen(
              initialPath: state.uri.queryParameters['path'],
            ),
            routes: [
              // Use query parameter for the full folder path so slashes are safe
              GoRoute(
                name: AppRouteName.filesFolder,
                path: 'folder',
                builder: (context, state) => AndroidFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
              GoRoute(
                name: AppRouteName.filesSearch,
                path: 'search',
                builder: (context, state) => SearchFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
            ],
          ),
        ],
      ),
```
so you can see the route AppRouteName.filesRoot is the root route and AppRouteName.filesFolder is the child route. root route is also currently using the file_screen_page as the builder but I want a seperate file to be made for file_folder_root_page which will show the internal storage card clicking on which we will be routed to the file_screen_page with the route folder with builder parameter maybe /0 or whatever it is.

so this thing in the file_screen_page.dart 

```dart

  Widget _buildRoots(List<Directory> roots) {
    print('🎨 [AndroidFilesScreen] _buildRoots: ${roots.length} items');
    return ListView(
      children: roots.map((d) {
        print('  - Root: ${d.path}');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.sd_storage, size: 32, color: Colors.blue),
            title: Text(
              d.path,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Storage Root'),
            onTap: () => _openFolder(d.path),
          ),
        );
      }).toList(),
    );
  }
```
should be thus removed from the file_screen_page and moved to the new page for root directory showing all the storage compartments like internal storage ssd card. and on clicking on any of the storage compartments we will be routed to the file_screen_page with the route folder with builder parameter maybe /0 or whatever it is.
root should be a page with only the internal storage card which is currently being shown in the the file screen page. and the file screen page should be a child of this root page. 



# TASK 2

create a layout for this file folder screen being shown. as you can see these 2 components being used in the file_screen_page. 

```dart 


  Widget _buildHeader(
    BuildContext context,
    List<FileInfo> visibleFiles,
    bool loading,
  ) {
    final t = AppLocalizations.of(context);
    final p = _maybeProvider();
    final enabled = widget.selectable && (p?.isEnabled ?? false);
    final maxLimitActive = p?.maxSelectable != null;
    final allOnPage = (!maxLimitActive && enabled)
        ? (p?.areAllSelected(visibleFiles) ?? false)
        : false;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.widgets_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t.t('files_header_title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (loading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigation logic remains same
              if (widget.isFullscreenRoute == true) {
                context.pushNamed(
                  'files.search.fullscreen', // ensure route exists
                  queryParameters: {'path': _currentPath},
                );
              } else {
                context.pushNamed(
                  AppRouteName.filesSearch,
                  queryParameters: {'path': _currentPath},
                );
              }
            },
            tooltip: t.t('common_search'),
          ),
          if (widget.selectable && !maxLimitActive)
            IconButton(
              icon: Icon(
                !enabled
                    ? Icons.check_box_outline_blank
                    : (allOnPage
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
              ),
              tooltip: !enabled
                  ? t.t('files_enable_selection_tooltip')
                  : (allOnPage
                        ? t.t('files_clear_page_tooltip')
                        : t.t('files_select_all_page_tooltip')),
              onPressed: () {
                final prov = _maybeProvider();
                if (prov == null) return;
                prov.cyclePage(visibleFiles);
              },
            )
          else if (widget.selectable && maxLimitActive)
            const SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: t.t('files_more_tooltip'),
            ),
        ],
      ),
    );
  }

```
this is the header of the file_screen_page.dart
and 

```dart

Padding(
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
```
this is the component part in the file_screen_page.dart which shows the current directory and item count and and other funcitionality buttons whose action methods  are written in the file_screen_page.dart - _openFilterDialog and _showNewFolderSheet methods. now the problem is that whevener a folder is opened the page changes as whole since the parameters of the route is changed and whole page is rebuilded but I don't want these 2 parts of page (_buildHeader and the current directory info + the action buttons) to rebuild along with the page. so make a persistent layout which will be not be rebuilded when the route is chagned (parameters are changed) only the listing of files and folders will be rebuilded i.e. file_screen_page.dart will be rebuilded. not this new layout. make this new layout file in the layout folder. also make it use the global provider for the file system i.e. FileSystemProvider. and update this shell in the home_shell routing config accordingly. put shell route for this layout in the home_shell routing config to make it actually persistent and not rebuild and only the item_count and current_directory_name should be updated not whole thing rebuilded. also remove the things which are shifted to the new layout from the file_screen_page.dart.


```dart
StatefulShellBranch(
        navigatorKey: fileNavKey,
        routes: [
          GoRoute(
          name: AppRouteName.filesRoot,
            path: '/files',
            builder: (context, state) => AndroidFilesScreen(
              initialPath: state.uri.queryParameters['path'],
            ),
            routes: [
              // Use query parameter for the full folder path so slashes are safe
              GoRoute(
                name: AppRouteName.filesFolder,
                path: 'folder',
                builder: (context, state) => AndroidFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
              GoRoute(
                name: AppRouteName.filesSearch,
                path: 'search',
                builder: (context, state) => SearchFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
            ],
          ),
        ],
      ),
``` -->

<!-- 


# Task 1
ok as you can see that you have done changes in the home_shell.dart file. now do some similar changes in the file_selection_shell.dart which contains the route for selection panel of file folders.

```dart
GoRoute(
        name: AppRouteName.filesRootFullscreen,
        path: '/files-fullscreen',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AndroidFilesScreen(
            initialPath: state.uri.queryParameters['path'],
            selectable: true,
            isFullscreenRoute: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
          ),
        ),
        routes: [
          GoRoute(
            name: AppRouteName.filesFolderFullScreen,
            path: 'folder',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: AndroidFilesScreen(
                initialPath: state.uri.queryParameters['path'],
                selectable: true,
                isFullscreenRoute: true,
                selectionId: state.uri.queryParameters['selectionId'],
                selectionActionText: state.uri.queryParameters['actionText'],
              ),
            ),
          ),
          GoRoute(
            name: AppRouteName.filesSearchFullscreen, // NEW
            path: 'search',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: SearchFilesScreen(
                initialPath: state.uri.queryParameters['path'],
                selectable: true, // NEW
                isFullscreenRoute: true, // NEW
                selectionId: state.uri.queryParameters['selectionId'],
                selectionActionText: state.uri.queryParameters['actionText'],
              ),
            ),
          ),])
      
```
this is the selection shell route config and this is the home_shell route config related to file 

```dart 
      StatefulShellBranch(
        navigatorKey: fileNavKey,
        routes: [
          GoRoute(
            name: AppRouteName.filesRoot,
            path: '/files',
            builder: (context, state) =>
                const FilesRootPage(), // NEW: Storage volumes
            routes: [
              // Persistent shell for folder browsing only
              ShellRoute(
                builder: (context, state, child) =>
                    FileBrowserShell(child: child),
                routes: [
                  GoRoute(
                    name: AppRouteName.filesFolder,
                    path: 'folder',
                    builder: (context, state) => AndroidFilesScreen(
                      initialPath: state.uri.queryParameters['path'],
                    ),
                  ),
                ],
              ),
              // Search stays as direct child (no shell)
              GoRoute(
                name: AppRouteName.filesSearch,
                path: 'search',
                builder: (context, state) => SearchFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
            ],
          ),
        ],
      ),
```

now selection menu should follow the same thing root should have the root page and then after that it should navigate further. keep in mind that this selection shell is being accessed by the functionality_list.dart file. so keep in mind about forwarding the parameters being passed there. and nothing should break. -->


<!-- # Task 1

we have to create breadcrump in the file browser shell. ok so we have to create a breadcrump widget and then we have to add it to the file browser shell exactly at the place where the current directory name is being shown. also I want that those breadcrump should be clickable and tracable.
suppose I am in the folder /storage/emulated/0/Download/hello and I want to go to the parent folder then I should be able to click on the parent folder breadcrump and it should navigate to the parent folder and after doing so the breadcrump should be updated to /storage/emulated/0/Download and then routing stack should also be managed i.e. suppose this wast the stack internal storage > download > hello (then clicked the internal storage breadcrump then the stack should tracked back to internal storage)

# Task 2

in the file browser shell you have this icon for bulk selecting files in a folder  

```dart
if (!maxLimitActive)
            IconButton(
              icon: Icon(
                !enabled
                    ? Icons.check_box_outline_blank
                    : (allOnPage
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
              ),
              tooltip: !enabled
                  ? t.t('files_enable_selection_tooltip')
                  : (allOnPage
                        ? t.t('files_clear_page_tooltip')
                        : t.t('files_select_all_page_tooltip')),
              onPressed: () {
                final prov = _maybeProvider();
                if (prov == null) return;
                prov.cyclePage(visibleFiles);
              },
            )
          else if (maxLimitActive)
            const SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: t.t('files_more_tooltip'),
            ),
```
should not be there in the build header section. instead it should be there in the current directory info widget that in the place of this icon when fullscreen is true.

```dart
          IconButton(
            onPressed: () {
              showNewFolderSheet(
                context: context,
                onCreate: (String folderName) async {
                  if (_currentPath == null || folderName.trim().isEmpty) return;
                  await context.read<FileSystemProvider>().createFolder(
                    _currentPath!,
                    folderName,
                  );
                },
              );
            },
            icon: const Icon(Icons.create_new_folder_outlined),
          ),

``` <---- this icon should be replaced with the bulk select icon when fullscreen is true -->

<!-- 

# Task 1

ok so see pdf_viewer_page.dart file so I want you to fix that page. first of all I want only image of the page is being shown put instead show the real pdf pages yrr. also I want that those pages should be scrollable and zoomable by 2 fingure gestures as we already know. also there is a weird text there saying page x of y below each page which should not be there fix this instead as we scrolldown the scrollar in side should show what the page it actually is.

# Task 2

ok so as you can see that on the top right corner of the page viewer there is a button for vert more options on which this pdf_option_pick_sheet.dart is being shown. now I want that on clicking on the rename button it should open pick sheet for renameing the file. 

```dart

  Future<void> _handleFileRename(FileInfo file) async {
    await showRenameFileSheet(
      context: context,
      initialName: file.name,
      onRename: (newName) async {
        context.read<FileSystemProvider>().renameFile(file, newName).then((_) {
          RecentFilesSection.refreshNotifier.value++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File renamed successfully')),
          );
        });
      },
    );
  }
```
use the this method for renaming and here is the file for pick sheet of renaming rename_file_sheet.dart.

then for deleting use the delete_file_sheet.dart file. and for instance forget other optinos in the pick sheet other than these 2. also when you are deleting the file or renaming it it should be updated in the global provider for whole file folder system provider.

# Task 3
if the pdf we are trying to open is protected with password then ask for password and if it is correct then open the pdf else show a snackbar saying that the pdf is protected with password. and currently opening a protected pdf shows the page with bunch of error offcourse. fix it.



so suppose a pdf is given of 10 pages then split functionality will allow you to make different ranges of pages and then make a pdf for each of the range and then save it in the file system.  -->

This split feature lets the user define **any number of page ranges** for a selected PDF and then generates a separate PDF file for each range. 

## UI behavior

- The user selects a PDF (for example, a 10-page file).   
- The UI shows the **total pages** and provides inputs for `Start page` and `End page`
- also a scrollable row of small but yet viewably large peeview of each page in scrollable row so that user can see that these are the pages and thus could select the range. however these previews are not actionable at all and only for viewing.   
- The user can add **multiple ranges**, including overlapping ones, for example:
  - Range 1: 1–5  
  - Range 2: 4–10  
- Each added range is listed (e.g., “Range 1: Pages 1–5”), with the ability to remove a range from the list.   
- When the user taps **Split PDF**:
  - The button is disabled and a loader/progress indicator is shown while processing. 
  - On success, the UI shows a dialog/notification listing created files (e.g., `file-pages_1_to_5.pdf`, `file-pages_4_to_10.pdf`). 
  - On failure (invalid range, no ranges, file error), a message/snackbar is shown with the error. 

## Service behavior

- The service receives:
  - The **source PDF file**
  - A **list of ranges** (each with start page, end page, and optional custom name) 
- It first:
  - Reads the **total page count** of the PDF. 
  - Validates each range:
    - `start >= 1`, `end <= totalPages`, `start <= end`. 
    - At least one range must exist. 
  - If validation fails, it returns a result with `success = false` and error messages. 
- For each valid range:
  - The service creates a **new PDF document** that contains only pages from that range (for example, 1–5). 
  - Overlapping ranges are treated independently, so the same page can appear in multiple output PDFs. 
  - A file name is generated, for example:
    - Original: `myfile.pdf`
    - Range: 1–5 → `myfile-pages_1_to_5.pdf` (or with custom name if provided). 
  - The new PDF is **saved to an output directory** (either a default app directory or a configurable path). 
- After processing all ranges:
  - The service returns a **SplitResult** that includes:
    - `success` flag  
    - List of output files  
    - List of output file names  
    - A human-readable message (like “Successfully split PDF into 2 files”). 
- The service also exposes helper methods to:
  - Get page count for a PDF (used by the UI to show total pages). 
  - Delete a generated split file if the user wants to remove it. 
  - Open a split PDF file using the system viewer. 

## Package responsibility (conceptual)

- One package is used to **read the PDF** and get its page count.   
- One package is used to **construct and write new PDF files** for each range.   
- File system helpers are used to:
  - Get an output directory
  - Create folders like `/PdfKit/splits`
  - Read/write/delete files.   
- A file-opening utility is used to **open the resulting PDFs** from your app.   

From the UI perspective, it is “select PDF → define ranges → tap Split → see list of created files,” and from the service perspective, it is “validate ranges → create one new PDF per range → save files → return info back to UI,” with overlapping ranges fully supported.

!!! CAUTION - no rasterization should be done to the pdf at all any page. the pages should be exact copy of the original pdf pages. !!!

make the service file in the service folder. and the page in the pages folder and the fix it route in the app_router.dart file. also see the functionality_list.dart file as you can see that other functionality button routing with query to be send is there. write for split pdf too. so on the home_page this functionality_list will be shown and as you will set the routing in the functionality_list.dart file for split pdf it will be sent to the app_router.dart file and then to the split pdf page. I want on click of the split button it should be routed to selection layout and prompted for selecting pdfs only. see for how other functionality prompted for selection layout for selection of pdf only or image only. restriction are pdf only file selection, min pdf = 1, max pdf = 1. then go on the split pdf page. see for other pages like protect_pdf page or the merge_pdf page and accordingly design this page in similar manner. funcitonality name as heading and then small descriptio of the funcitonlity below than the naming rule you want to keep for the newly generated pdfs. allow user to select _____(1) the underscore place and the number place should be replaced by the number of pages in the pdf automatically. then below that the row scrollable pdf preview such that pdf pages are smaller but yet recognizable pages. then range creator or remover and decide what range and then split pdf button in the bottom navigation bar. remember everythin should be app_theme according no hard coded size or color or font or any other property. and just use the component in theme I have setted their properties whcih should be same in whole app.