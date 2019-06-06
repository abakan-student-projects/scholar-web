package;

import Lambda;
import model.CodeforcesTaskTag;
import Std;
import model.CodeforcesTaskTag;
import model.CodeforcesTask;
import haxe.PosInfos;
import haxe.ds.ArraySort;
import utils.IterableUtils;
import AdaptiveLearning.CategoryLevel;
import haxe.ds.StringMap;
import model.CodeforcesTag;
import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

/**
 * Auto generated AdaptiveLearningTest for MassiveUnit.
 * This is an example test class can be used as a template for writing normal and async tests
 * Refer to munit command line tool for more information (haxelib run munit)
 */
class AdaptiveLearningTest {

	@Test
	public function testCanUserSolveTagAndLevel() {
		var categoryLevel: CategoryLevel = {category: null, level:2, countSolved:11};
		Assert.isTrue(AdaptiveLearning.canUserSolveTagAndLevel(3,categoryLevel));
	}
	@Test
	public function testCalcLearnerLevel() {
		var i = 1;
		var tags = [];
		while(i < 5) {
			var tag = new CodeforcesTag();
			tag.id = i++;
			tags.push(tag);
		}
		var learnerLevel = AdaptiveLearning.calcLearnerLevel(tags);
		var categoryLevel:Array<CategoryLevel> = [];
		for (t in tags) {
			categoryLevel.push({category: t, level:1, countSolved: 0});
		}
		var actualValue = learnerLevel;
		var expectedValue:StringMap<CategoryLevel> = IterableUtils.createStringMap(categoryLevel, function(c){return Std.string(c.category.id);});
		Assert.areEqual(actualValue.get(Std.string(1)).countSolved,expectedValue.get(Std.string(1)).countSolved);
		Assert.areEqual(actualValue.get(Std.string(2)).category.id,expectedValue.get(Std.string(2)).category.id);
		Assert.areEqual(actualValue.get(Std.string(3)).level,expectedValue.get(Std.string(3)).level);
	}

	@Test
	@TestDebug
	public function testExecuteFilter() {
		var tasks: Array<CodeforcesTask> = [];
		var taskTags = new StringMap<Array<CodeforcesTaskTag>>();
		var tasksTags: Array<CodeforcesTaskTag> = [];
		var categoryLevels = new StringMap<CategoryLevel>();
		var tags: Array<CodeforcesTag> = [];
		var i = 1;
		var ids = [1,2,3,4,5];
		while (i < 5) {
			var task = new CodeforcesTask();
			var tag = new CodeforcesTag();
			var taskTag = new CodeforcesTaskTag();
			/*task.id = i;
			tag.id = i;*/
			taskTag.task = task;
			taskTag.tag = tag;
			tasks.push(task);
			tags.push(tag);
			tasksTags.push(taskTag);
			i++;
		}
		taskTags = IterableUtils.createStringMapOfArrays(tasksTags, function(t){return Std.string(t.task.id);});
		for (t in tags) {
			categoryLevels.set(Std.string(t.id),{category:t, level: Std.parseInt(Std.string(t.id)), countSolved: 10});
		}
		var execFilter = AdaptiveLearning.executeFilter(tasks,taskTags,categoryLevels);
		Assert.areEqual(tasks[0],execFilter[0]);
	}

	@Test
	@TestDebug
	public function testCanUserLevelUpTag() {
		var tags: Array<CodeforcesTag> = [];
		var learnerLevel = new StringMap<CategoryLevel>();
		var i = 1;
		while (i < 5) {
			var tag = new CodeforcesTag();
			tag.id = i;
			tags.push(tag);
		}
		learnerLevel.set(Std.string(tags[0].id),{category:tags[0], level: 2, countSolved: 51});
		learnerLevel.set(Std.string(tags[1].id),{category:tags[1], level: 4, countSolved: 15});
		learnerLevel.set(Std.string(tags[2].id),{category:tags[2], level: 1, countSolved: 10});
		learnerLevel.set(Std.string(tags[3].id),{category:tags[3], level: 3, countSolved: 101});
		var actualValue: StringMap<CategoryLevel> = AdaptiveLearning.canUserLevelUpTag(tags, learnerLevel);
		var expectedValue = new StringMap<CategoryLevel>();
		expectedValue.set(Std.string(tags[0].id),{category:tags[0], level: 3, countSolved: 0});
		expectedValue.set(Std.string(tags[1].id),{category:tags[1], level: 4, countSolved: 15});
		expectedValue.set(Std.string(tags[2].id),{category:tags[2], level: 1, countSolved: 10});
		expectedValue.set(Std.string(tags[3].id),{category:tags[3], level: 4, countSolved: 0});
		Assert.areEqual(expectedValue.get(Std.string(tags[0].id)).level, actualValue.get(Std.string(tags[0].id)).level);
	}

	/*@Ignore("the test isn`t work right") @Test
	public function testSelectTasks() {

	}

	@Ignore("the test isn`t work right") @Test
	public function testNextTask() {

	}

	@Ignore("the test isn`t work right") @Test
	public function testEmulateSolution() {

	}

	@Ignore("the test isn`t work right") @Test
	public function testSelectTasksForChart() {

	}

	@Ignore("the test isn`t work right") @Test
	public function testCalcUserLearnerLevelChart() {

	}*/

//	public function new()
//	{
//	}
//
//	@BeforeClass
//	public function beforeClass()
//	{
//	}
//
//	@AfterClass
//	public function afterClass()
//	{
//	}
//
//	@Before
//	public function setup()
//	{
//	}
//
//	@After
//	public function tearDown()
//	{
//	}
//
//	@AsyncTest
//	public function testAsyncExample(factory:AsyncFactory)
//	{
//		var handler:Dynamic = factory.createHandler(this, onTestAsyncExampleComplete, 300);
//		var timer = Timer.delay(handler, 200);
//	}
//
//	function onTestAsyncExampleComplete()
//	{
//		Assert.isFalse(false);
//	}
//
//	/**
//	 * test that only runs when compiled with the -D testDebug flag
//	 */
//	@TestDebug
//	public function testExampleThatOnlyRunsWithDebugFlag()
//	{
//		Assert.isTrue(true);
//	}


}